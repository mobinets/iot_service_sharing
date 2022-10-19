%Plot_ComputionTime_CDF
%使用的是code_v1.6/data/TaskNumToServerNumRation_data2。这组数据跑完后三个算法的缓存和计算资源分配结果是子任务数量为600时的结果


Possionrate_sum = zeros(1,Tasknum);
for j=1:userNum
    for i=1:Tasknum
        if Taskgraph(i,i,j) ~= 0
            Possionrate_sum(i) = Possionrate_sum(i) + Possionrate(j);
        end
    end
end


%先计算P3的
Cache = preCache_p3;
TaskComputationSpeed = preTaskComputationSpeed_p3;

%计算Cachelocation和Cachestatus
Cachelocation = zeros(1,Tasknum);%Cachelocation(i)表示任务i被缓存到哪台服务器，0表示没被缓存
Cachestatus = zeros(1,Tasknum);%0表示没被缓存，1表示没有计算资源竞争，2表示存在计算资源竞争
for j=1:Servernum
    count = 0; %第j台边缘服务器缓存了几种类型任务
    for i=1:Tasknum
        if Cache(i,j) == 1
            count = count + 1;
        end
    end
    
    for i=1:Tasknum
        if Cache(i,j) == 1
            Cachelocation(i) = j;
            if count == 1
                Cachestatus(i) = 1;
            else
                Cachestatus(i) = 2;
            end
        end
    end
end

ComputationTime_p3 = zeros(1,Tasknum);

for i=1:Tasknum
    if(Cachelocation(i) == 0)%任务i在本地执行
        for k = 1:userNum
            if(Taskgraph(i, i, k) == 0)
                continue;
            end
            
             r = Computespeed_Local(i,k); %第k个本地CPU对第i种任务的本地处理速度
             B = TaskSize(i);
             time = 1/(r/B - Possionrate(k));
             
             ComputationTime_p3(i) = ComputationTime_p3(i) + time*Possionrate(k)/Possionrate_sum(i);
        end
        
    else %任务i在服务器上执行，速度从TaskComputationSpeed中获取
        ComputationTime_p3(i) = 1/((TaskComputationSpeed(i)/TaskSize(i)) - Possionrate_sum(i));      
    end   
    
end




%再计算infocom的------------------------------------------------------------------
Cache = preCache_infocom;
TaskComputationSpeed = preTaskComputationSpeed_infocom;

%计算Cachelocation和Cachestatus
Cachelocation = zeros(1,Tasknum);%Cachelocation(i)表示任务i被缓存到哪台服务器，0表示没被缓存
Cachestatus = zeros(1,Tasknum);%0表示没被缓存，1表示没有计算资源竞争，2表示存在计算资源竞争
for j=1:Servernum
    count = 0; %第j台边缘服务器缓存了几种类型任务
    for i=1:Tasknum
        if Cache(i,j) == 1
            count = count + 1;
        end
    end
    
    for i=1:Tasknum
        if Cache(i,j) == 1
            Cachelocation(i) = j;
            if count == 1
                Cachestatus(i) = 1;
            else
                Cachestatus(i) = 2;
            end
        end
    end
end

ComputationTime_infocom = zeros(1,Tasknum);

for i=1:Tasknum
    if(Cachelocation(i) == 0)%任务i在本地执行
        for k = 1:userNum
            if(Taskgraph(i, i, k) == 0)
                continue;
            end
            
             r = Computespeed_Local(i,k); %第k个本地CPU对第i种任务的本地处理速度
             B = TaskSize(i);
             time = 1/(r/B - Possionrate(k));
             
             ComputationTime_infocom(i) = ComputationTime_infocom(i) + time*Possionrate(k)/Possionrate_sum(i);
        end
        
    else %任务i在服务器上执行，速度从TaskComputationSpeed中获取
        ComputationTime_infocom(i) = 1/((TaskComputationSpeed(i)/TaskSize(i)) - Possionrate_sum(i));      
    end   
    
end



%最后计算iwqos的------------------------------------------------------------------
Cache = preCache_iwqos;
TaskComputationSpeed = preTaskComputationSpeed_iwqos;

%计算Cachelocation和Cachestatus
Cachelocation = zeros(1,Tasknum);%Cachelocation(i)表示任务i被缓存到哪台服务器，0表示没被缓存
Cachestatus = zeros(1,Tasknum);%0表示没被缓存，1表示没有计算资源竞争，2表示存在计算资源竞争
for j=1:Servernum
    count = 0; %第j台边缘服务器缓存了几种类型任务
    for i=1:Tasknum
        if Cache(i,j) == 1
            count = count + 1;
        end
    end
    
    for i=1:Tasknum
        if Cache(i,j) == 1
            Cachelocation(i) = j;
            if count == 1
                Cachestatus(i) = 1;
            else
                Cachestatus(i) = 2;
            end
        end
    end
end

ComputationTime_iwqos = zeros(1,Tasknum);

for i=1:Tasknum
    if(Cachelocation(i) == 0)%任务i在本地执行
        for k = 1:userNum
            if(Taskgraph(i, i, k) == 0)
                continue;
            end
            
             r = Computespeed_Local(i,k); %第k个本地CPU对第i种任务的本地处理速度
             B = TaskSize(i);
             time = 1/(r/B - Possionrate(k));
             
             ComputationTime_iwqos(i) = ComputationTime_iwqos(i) + time*Possionrate(k)/Possionrate_sum(i);
        end
        
    else %任务i在服务器上执行，速度从TaskComputationSpeed中获取
        ComputationTime_iwqos(i) = 1/((TaskComputationSpeed(i)/TaskSize(i)) - Possionrate_sum(i));      
    end   
    
end

cdfplot(ComputationTime_p3);
%cdfplot(ComputationTime_infocom);
%cdfplot(ComputationTime_iwqos);

