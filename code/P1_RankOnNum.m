function [preCache,preTaskComputationSpeed,preFinishTime] = P1_RankOnNum(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Computespeed_Local,ComputeSpeed_server)
%P1_RankOnNum + P2_RankOnNum 代替掉了P1 + P2（已删除）

%外层函数P1，决定缓存策略Cache，作为P2的输入调用P2
%每次随机改变一个server的缓存策略，注意判断改变之后是否满足每种类型任务最多被缓存一次，以及服务器的内存大小是否超出限制
%preCache缓存决策，preTaskComputationSpeed边缘服务器分配给各任务的计算速率，preFinishTime平均每个DAG的完成时间加权平均
%
%P1的结束条件是什么？暂时是迭代100次

%ServerMemory(i)表示第i个边缘服务器的内存大小
%TaskMemory(i)表示缓存第i种类型任务所需的内存大小  1*Tasknum

%合成的DAG中每种类型子任务最终的泊松到达参数和
Possionrate_sum = zeros(1,Tasknum);
for j=1:userNum
    for i=1:Tasknum
        if Taskgraph(i,i,j) ~= 0
            Possionrate_sum(i) = Possionrate_sum(i) + Possionrate(j);
        end
    end
end

preCache = zeros(Tasknum,Servernum);%Tasknum*Servernum的矩阵，Cache(i,j)==1/0表示server j缓存/没缓存任务i。一开始初始化一个都不缓存的策略
%hasCached = zeros(1,Tasknum);%hasCached(i) =1表示任务i已经被缓存了

%初始所有边缘服务都不缓存任何任务，Cache中所有元素都为0
%调用P2，得到现在的最终延迟
[preTaskComputationSpeed,preFinishTime] = P2_RankOnNum(Tasknum,userNum,Servernum,preCache,Possionrate,Possionrate_sum,Taskgraph,Transferrate,Computespeed_Local,ComputeSpeed_server);

bestCache = preCache;
bestTaskComputationSpeed = preTaskComputationSpeed;
bestFinishTime = preFinishTime;

w = 2;%这个参数的设置，会影响到缓存策略是否容易改变
Iterationnum = 500000;%这里暂时以迭代10000次作为结束条件。结束条件是否应该是每次得到的时间波动很小？
for iteration =1:Iterationnum
    changeIndex = randi(Servernum,1,1);%随机选中一个服务器
    %随机更新这个服务器上的缓存策略
    hasCached = HasCacheTasks(changeIndex,preCache,Tasknum,Servernum);%其他服务器上已经缓存任务情况
    newCache = preCache;
    newCache(:,changeIndex) = RandomCachePolicy(changeIndex,hasCached,ServerMemory,TaskMemory,Tasknum);
    
    %把新缓存策略带入P2，得到新的延迟结果
    [curTaskComputationSpeed,curFinishTime] = P2_RankOnNum(Tasknum,userNum,Servernum,newCache,Possionrate,Possionrate_sum,Taskgraph,Transferrate,Computespeed_Local,ComputeSpeed_server);
    
     if curFinishTime < bestFinishTime
        bestFinishTime = curFinishTime;
        bestCache = newCache;
        bestTaskComputationSpeed = curTaskComputationSpeed;
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

