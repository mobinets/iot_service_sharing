function [TaskComputationSpeed,AvgFinishtime,Finishtime] = P2_network_addFinishtime(Tasknum,userNum,Servernum,Cache,Possionrate,Possionrate_sum,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server)
%该函数与P2_network的唯一区别是，多了一个返回参数Finishtime，是一个1*userNum的矩阵，表示每个用户DAG任务的完成时间。
%该函数是2021.7.25为了加实验：纵轴为某个时间内完成的任务数量。与P3_network_addFinishtime函数配合使用

%当外层缓存策略固定，内层做计算资源的分配，这是内层函数P2
%现在每个子任务能够在哪里处理已经确定了，有的任务只能在本地执行，有的任务能在本地或者唯一缓存它的边缘服务器执行
%被缓存了的任务一定在边缘服务器执行，没被缓存的任务一定在本地执行（要不要设置被缓存的任务也可能在本地执行？）
%那么现在每个任务的执行位置都确定了
%如果某台服务器只缓存了一个任务的服务，那么这个任务的运行速度就是这个服务器所有速度
%如果一个服务器缓存了多个任务，那么这几个任务就存在计算资源的竞争关系
%都按服务器最快速度来计算出rank值，然后按照rank值的比值来划分计算资源（计算速度）
%最后分别几个DAG中最后一个任务的EFT，按λ的比值得到最后的时间结果

%Tasknum表示合成DAG中一共子任务种类数
%Cache表示缓存情况，是一个Tasknum*Servernum的矩阵，Cache(i,j)==1/0表示server j缓存/没缓存任务i
%Possionrate(i)表示第i个DAG（用户）的泊松分布λ值  1*userNum
%Possionrate_sum(i)表示第i种类型任务的总泊松分布λ值
%Taskgraph(:,:,i)表示第i个用户DAG的关联矩阵。
%Transferrate表示服务器之间的传输速率，
%   是一个(serverNum + userNum) * (serverNum + userNum)矩阵，serverNum + 1表示第一个用户的本地设备
%Computespeed_Local本地处理器对每种任务的计算速率 Tasknum * userNum
%   Computespeed_Local(i,j)表示第j个本地CPU对第i种任务的处理速度
%ComputeSpeed_server每个边缘服务器最大计算速度 ComputeSpeed_server(i)

Possionrate_total = 0;%所有用户的泊松分布参数之和，注意与Possionrate_sum数组每种类型任务泊松参数之和 是不一样的
for i=1:userNum
    Possionrate_total = Possionrate_total + Possionrate(i);
end

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

%先求每个任务的处理时间，得到新的DAG（点权重改变），然后用新DAG求rank值
Taskgraph_finally = zeros(Tasknum, Tasknum);%构造新的DAG Taskgraph_finally，拓扑上是合成之后的DAG 
for k=1:userNum
    for i=1:Tasknum
        for j=1:Tasknum
            if(i == j)
                continue;
            end
            
            if(Taskgraph_finally(i,j) ~= 0)
                continue;
            end
            
            if(Taskgraph(i,j ,k) == 0)
                continue;
            end
            
            Taskgraph_finally(i,j) = Taskgraph(i,j,k);  
        end
    end
end
%把边的权重变成通信时间
%Cal_Communicationtime
Taskgraph_finally = Cal_Communicationtime_network(Taskgraph_finally,Transferrate,Transferrate_network,Cachelocation,Tasknum,userNum,Servernum,Taskgraph,Possionrate,Possionrate_sum); %处理边的权重（通信时间），边的数据量 / 两个服务器的通信速率。对于本地执行的任务，通信时间需要计算加权平均

for i=1:Tasknum%处理A(i,i)，点的权重
    if Cachestatus(i) == 0 %任务i没被缓存，在本地执行。计算任务i的处理时间（是在各个本地CPU上处理时间的加权平均值）
        %DAG点的权重（A（i,i）），等于这个任务的处理时间
        Taskgraph_finally(i,i) = Cal_ComputetimeLocal(i,userNum,Possionrate,Possionrate_sum,Computespeed_Local,Taskgraph);
    else
        Taskgraph_finally(i,i) = Cal_ComputetimeServer_RankOnNum(i,Tasknum,userNum,Servernum,Cache,ComputeSpeed_server,Possionrate_sum,Taskgraph);
    end
end

%用新的DAG，计算每个任务的rank。注意需要在每个DAG中计算一个rank值，然后求加权平均
rank = zeros(Tasknum,userNum);
for i=1:userNum
    %使用Taskgraph(:,:,i)的拓扑，但使用Taskgraph_finally的点的权重与边的权重
    tempTaskgraph = Origintopo_NewWeight(Taskgraph(:,:,i),Taskgraph_finally,Tasknum);
    rank(:,i) = Rankup(tempTaskgraph,Tasknum);
end

rank_combine = zeros(1,Tasknum);%把每个DAG中计算出的各任务rank取加权平均。得到每个任务的rank值
for j=1:userNum
    for i=1:Tasknum
       rank_combine(i) = rank_combine(i) + rank(i,j)* Possionrate(j)/Possionrate_total;
    end
end

%Cachestatus == 2的那些任务（存在资源竞争的任务），需要按照rank_combine值比例划分对应边缘服务器上的计算速度
%TaskComputationSpeed(i)表示第i种任务在服务器上执行的速度。如果任务i在本地执行，那么A(i) ==0
TaskComputationSpeed = ComputationSpeedAllocation(rank_combine,Cache,Cachelocation,Cachestatus,Tasknum,Servernum,ComputeSpeed_server); %每种任务类型的计算速度。 A(i) = 0则任务在本地执行


%Cache和TaskComputationSpeed就是要求的结果，即缓存策略和计算资源分配策略
%接下来要根据缓存策略和计算资源分配策略，得到此时的每个DAG执行时间的加权平均值
%需要分别去算每个DAG，然后把每个DAG的延迟求加权平均
%现在很简单，因为缓存策略已经把offload策略给确定了，使用类似基于rank值的递归写法求最后一个任务结束时间就行了
%记录一个DAG中每个任务的结束时间，最大的那个就是整个DAG的计算时间
Finishtime = zeros(1,userNum);
for i=1:userNum
    [EFT,Lastfinishtask] = Cal_Taskfinishtime_network(i,Cachelocation,TaskComputationSpeed,Taskgraph,Tasknum,Servernum,Possionrate,Possionrate_sum,Computespeed_Local,Transferrate,Transferrate_network);
    Finishtime(i) = Lastfinishtask;
end

%现在已经得到了每个DAG的完成时间，按照泊松分布参数比例做加权平均
AvgFinishtime = 0;
for i=1:userNum
    AvgFinishtime = AvgFinishtime + Finishtime(i)*Possionrate(i)/Possionrate_total;
end




