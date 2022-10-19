function [preCache,preTaskComputationSpeed,preFinishTime,curUserFinishTime] = P1_iwqos_network_addFinishtime(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server)
%与P1_iwqos_network区别是多了一个返回参数Finishtime，是一个1*userNum的矩阵，表示每个用户DAG任务的完成时间
%该函数是2021.7.25为了加实验：纵轴为某个时间内完成的任务数量。与P2_network_addFinishtime函数配合使用

%在Copy_of_P1_iwqos的基础上，增加参数Transferrate_network，并且调用P2_network
    %考虑服务器间连通性

%iwqos这篇文章的缓存策略是直接根据贪心得到的，不需要迭代
%得到缓存策略后，直接带入P2_RankOnNum，得到计算资源分配策略和最终平均任务延迟


%合成的DAG中每种类型子任务最终的泊松到达参数和
Possionrate_sum = zeros(1,Tasknum);
for j=1:userNum
    for i=1:Tasknum
        if Taskgraph(i,i,j) ~= 0
            Possionrate_sum(i) = Possionrate_sum(i) + Possionrate(j);
        end
    end
end


%按照服务器的计算速度排序
ServerSpeed = zeros(Servernum,2);
for i=1:Servernum
    ServerSpeed(i,1) = ComputeSpeed_server(i);
    ServerSpeed(i,2) = i;
end


%排序，快排还得再写个函数，算了冒泡吧，注意速度最大的在最前面
for i=1:Servernum
    for j = 1:Servernum - i
        if(ServerSpeed(j,1) < ServerSpeed(j+1,1) )
            temp = ServerSpeed(j,1:2);
            ServerSpeed(j,1:2) = ServerSpeed(j+1,1:2);
            ServerSpeed(j+1,1:2) = temp;             
        end
    end
end

ServerSpeedRank = ServerSpeed(:,2);

preCache = zeros(Tasknum,Servernum);
Cached = zeros(1,Tasknum);
ServerMemoryRemain = ServerMemory;


%随机调一下取任务的顺序
taskset = randperm(Tasknum,Tasknum);

for k = 1:Servernum
    serverIndex = ServerSpeedRank(k);
    for i=1:Tasknum
        taskId = taskset(i);
        if (Cached(taskId) == 0) %该任务还没缓存
            if ServerMemoryRemain(serverIndex) >= TaskMemory(taskId)
                ServerMemoryRemain(serverIndex) = ServerMemoryRemain(serverIndex) - TaskMemory(taskId);
                preCache(taskId,serverIndex) = 1;
                Cached(taskId) = 1;
            end
        end
        
    end
end

% for k = 1:Servernum
%     serverIndex = ServerSpeedRank(k);
%     for i=1:Tasknum
%         if (Cached(i) == 0) %该任务还没缓存
%             if ServerMemoryRemain(serverIndex) >= TaskMemory(i)
%                 ServerMemoryRemain(serverIndex) = ServerMemoryRemain(serverIndex) - TaskMemory(i);
%                 preCache(i,serverIndex) = 1;
%                 Cached(i) = 1;
%             end
%         end
%         
%     end
% end


% for k = 1:Servernum
%     serverIndex = ServerSpeedRank(k);
%     for i=1:Tasknum
%         if (Cached(i) == 0) %该任务还没缓存
%             if ServerMemoryRemain(serverIndex) >= TaskMemory(i)
%                 ServerMemoryRemain(serverIndex) = ServerMemoryRemain(serverIndex) - TaskMemory(i);
%                 preCache(i,serverIndex) = 1;
%                 Cached(i) = 1;
%             end
%         end
%         
%     end
% end

%把preCache带入P2_RankOnNum
[preTaskComputationSpeed,preFinishTime, curUserFinishTime] = P2_network_addFinishtime(Tasknum,userNum,Servernum,preCache,Possionrate,Possionrate_sum,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);


end

