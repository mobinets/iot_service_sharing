function [preCache,preTaskComputationSpeed,preFinishTime,bestUserFinishTime] = P3_network_addFinishtime(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server)
%与P3_network区别是多了一个返回参数Finishtime，是一个1*userNum的矩阵，表示每个用户DAG任务的完成时间
%该函数是2021.7.25为了加实验：纵轴为某个时间内完成的任务数量。与P2_network_addFinishtime函数配合使用

%外层函数P1，决定缓存策略Cache，作为P2的输入调用P2
%每次随机改变一个server的缓存策略，注意判断改变之后是否满足每种类型任务最多被缓存一次，以及服务器的内存大小是否超出限制
%preCache缓存决策，preTaskComputationSpeed边缘服务器分配给各任务的计算速率，preFinishTime平均每个DAG的完成时间加权平均
%
%P1的结束条件是什么？暂时是迭代100次

%ServerMemory(i)表示第i个边缘服务器的内存大小
%TaskMemory(i)表示缓存第i种类型任务所需的内存大小  1*Tasknum

Graph = zeros(Tasknum,Tasknum);
for k = 1:userNum
    for i=1:Tasknum
        for j=1:Tasknum
            if Taskgraph(i,j,k) ~= 0
                Graph(i,j) = Taskgraph(i,j,k);%各个用户的dag，合成大的dag
            end
        end
    end
end

%合成的DAG中每种类型子任务最终的泊松到达参数和
Possionrate_sum = zeros(1,Tasknum);
for j=1:userNum
    for i=1:Tasknum
        if Taskgraph(i,i,j) ~= 0
            Possionrate_sum(i) = Possionrate_sum(i) + Possionrate(j);
        end
    end
end


%在过程中寻找最优解，最终作为返回值
bestCache = zeros(Tasknum,Servernum);
bestTaskComputationSpeed = zeros(1,Tasknum);
bestFinishTime = 999999999;%初始化为一个很大的值
bestUserFinishTime = zeros(1,userNum);

preCache = zeros(Tasknum,Servernum);
preTaskComputationSpeed = zeros(1,Tasknum);
preFinishTime = 999999999;

w = 1;%这个参数的设置，会影响到缓存策略是否容易改变
Iterationnum = 100;%这里暂时以迭代10000次作为结束条件。结束条件是否应该是每次得到的时间波动很小？
for iteration =1:Iterationnum
    
    newCache = zeros(1,Tasknum);%newCache(i)表示任务i的缓存位置，为0表示没有被缓存。一会需要转换为P2函数需要的cache形式
    remainServerMemory = ServerMemory;%每个服务器剩下的内存资源
    
    rudu = zeros(1,Tasknum);%记录Graph中每个任务的入度
    for i=1:Tasknum
        for j=1:Tasknum
            if Graph(i,j) < 0
                rudu(i) = rudu(i) + 1;
            end    
        end
    end
    
    Queue = zeros(1,0);%定义一个队列，初始为空（长度为0）
    for i=1:Tasknum
        if rudu(i) == 0
            Queue(end + 1) = i; %把入度为0的点加入队列。这个操作相当于队列的offer()
        end
    end
    
    while ~isempty(Queue(:)) %整体上是一个拓扑排序算法。入度为0的任务进入队列
        tem_TaskId = Queue(1);%Queue.peek()
        Queue(1) = [];%Queue.poll()
        
        if Graph(tem_TaskId,tem_TaskId) == 0
            continue;
        end
        
        %找到tem_TaskId这个任务所有前驱任务中，通信数据量最大的那个
        pre_TaskId = 0;
        maxEdge = 0;
        for i=1:Tasknum
            if i == tem_TaskId
                continue;
            end
            
            if Graph(i,tem_TaskId) > maxEdge
                maxEdge = Graph(i,tem_TaskId);
                pre_TaskId = i;
            end
        end
        
        if pre_TaskId == 0 %任务tem_TaskId没有前驱任务，它随机选择一个服务器
            availableServer = zeros(1,0);%先统计哪些服务器的容量大于TaskMemory(tem_TaskId)
            len = 0;
            for k = 1:Servernum
                if remainServerMemory(k) >= TaskMemory(tem_TaskId)
                    availableServer(end + 1) = k;
                    len = len + 1;
                end
            end
            
             changeIndex = randi([0,len],1,1); %注意现在是0~len之间，0表示不缓存。否则缓存在服务器availableServer(changeIndex)上
             if changeIndex~=0
                newCache(tem_TaskId) = availableServer(changeIndex); %剩余内存资源减去TaskMemory(tem_TaskId)
                remainServerMemory(availableServer(changeIndex)) = remainServerMemory(availableServer(changeIndex)) - TaskMemory(tem_TaskId);
             end
        else %任务tem_TaskId有前驱任务,找到与pre_TaskId所缓存的服务器（或者本地）通信速度最快的服务器（或本地）
            %最好是能在一个服务器（或者都在本地），速度最快（通信时间为0）
            if newCache(pre_TaskId) == 0
                newCache(tem_TaskId) = 0;
            else %前驱任务pre_TaskId在边缘服务器执行
                serverIndex = newCache(pre_TaskId);
                if remainServerMemory(serverIndex) >= TaskMemory(tem_TaskId)  %如果前驱任务所在服务器的内存还足够，就在这个服务器缓存
                    newCache(tem_TaskId) = serverIndex;
                    remainServerMemory(serverIndex) = remainServerMemory(serverIndex) - TaskMemory(tem_TaskId);
                else %否则，从内存资源足够的服务器中，找到与服务器serverIndex之间通信速度最快的服务器。有可能所有服务器内存都不够，那就本地执行
                    tempServerIndex = 0;
                    maxCommunicateSpeed = 0;
                    for k = 1:Servernum
                        %if remainServerMemory(k) >= TaskMemory(tem_TaskId) &&Transferrate(k, serverIndex) > maxCommunicateSpeed
                        if remainServerMemory(k) >= TaskMemory(tem_TaskId)
                            rate = Transferrate(k, serverIndex);
                            if Transferrate_network(k, serverIndex) == 0
                                rate = rate/2;
                            end
                            if rate > maxCommunicateSpeed
                                maxCommunicateSpeed = rate;
                                tempServerIndex = k;
                            end
                           
                        end
                    end
                    
                    newCache(tem_TaskId) = tempServerIndex;
                    if tempServerIndex~= 0
                        remainServerMemory(tempServerIndex) =  remainServerMemory(tempServerIndex) - TaskMemory(tem_TaskId);
                    end
                end
            end
            
        end
        
        %把任务tem_TaskId的所有后继任务的入度-1，并把入度为0的任务加入Queue队列
        for i=1:Tasknum
            if i == tem_TaskId
                continue;
            end
            
            if Graph(tem_TaskId, i) > 0
                rudu(i) = rudu(i) - 1;
                if rudu(i) == 0
                     Queue(end + 1) = i;
                end
            end
        end
        
    end
    
    %把newCache转换为P2函数需要的cache参数形式！！！！！！！！！！！！！
    newCache_temp = zeros(Tasknum,Servernum);
    for i = 1:Tasknum
        if newCache(i) ~= 0
            newCache_temp(i, newCache(i)) = 1;
        end
    end
    
    newCache = newCache_temp;
    
    %把新缓存策略带入P2，得到新的延迟结果
    [curTaskComputationSpeed,curFinishTime,curUserFinishTime] = P2_network_addFinishtime(Tasknum,userNum,Servernum,newCache,Possionrate,Possionrate_sum,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
    
     if curFinishTime < bestFinishTime
        bestFinishTime = curFinishTime;
        bestCache = newCache;
        bestTaskComputationSpeed = curTaskComputationSpeed;
        bestUserFinishTime = curUserFinishTime;
     end
    
    %根据新旧缓存策略得到的延迟结果，判断要不要更新缓存策略
    probaility = 1/(1 + exp((curFinishTime-preFinishTime)/w));
    temp = [0,1];%以probaility的概率取到0，表示更新缓存决策，以1-probaility概率取到1表示不更新
    prob = [probaility,1-probaility];
    update = randsrc(1,1,[temp;prob]);
    if(update == 0)
        preTaskComputationSpeed = curTaskComputationSpeed;
        preFinishTime = curFinishTime;
        preCache = newCache;
    end
    
end

preCache = bestCache;
preTaskComputationSpeed = bestTaskComputationSpeed;
preFinishTime = bestFinishTime;

end

