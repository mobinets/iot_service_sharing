function [TaskComputationSpeed,AvgFinishtime] = P2_infocom_network(Tasknum,userNum,Servernum,Cache,Possionrate,Possionrate_sum,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server)
%当外层缓存策略固定，内层做计算资源的分配，这是内层函数
%现在不考虑边，每个任务单独考虑
%2021/1/23，修改rank的计算方式，是直接从合成的DAG中得到，而不是分别计算这个任务在每个用户DAG中的rank，然后求泊松参数的加权平均

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

TaskTime = zeros(Tasknum);%各任务计算时间
for i=1:Tasknum
    if Cachestatus(i) == 0%任务i没被缓存，在本地执行
        TaskTime(i) = Cal_ComputetimeLocal(i,userNum,Possionrate,Possionrate_sum,Computespeed_Local,Taskgraph);
    else %在服务器上计算，都按所在服务器的最大速度来执行
        TaskTime(i) = Cal_ComputetimeServer(i,userNum,Servernum,Cache,ComputeSpeed_server,Possionrate_sum,Taskgraph);
    end
end

%现在直接从合成的DAG拓扑中得到每个任务的rank值，不需要分别计算该任务在每个用户DAG中的优先级，然后根据泊松分布参数的权重得到该任务最终rank值
%现在每个任务的rank值到最后一个任务的最长路径长度）就是任务本身的执行时间
rank_combine = zeros(1,Tasknum);
for i=1:Tasknum
    rank_combine(i) = TaskTime(i);
end

% rank = zeros(Tasknum,userNum);
% for k = 1:userNum
%     for i = 1:Tasknum
%         if Taskgraph(i,i,k) == 0
%             rank(i,k) = 0;
%         else %现在不考虑边，优先级（到最后一个任务的最长路径长度）就是任务本身的执行时间
%             rank(i,k) = TaskTime(i);
%         end
%     end
% end


% rank_combine = zeros(1,Tasknum);%把每个DAG中计算出的各任务rank取加权平均。得到每个任务的rank值
% for j=1:userNum
%     for i=1:Tasknum
%        rank_combine(i) = rank_combine(i) + rank(i,j)* Possionrate(j)/Possionrate_total;
%     end
% end

%在服务器执行的任务被分配的计算速度
TaskComputationSpeed = zeros(1,Tasknum);  %如果在本地计算，那么TaskComputationSpeed(i) == 0，如果Cachestatus(i) == 1，那么速度是所在服务器的全速

Serverranksum = zeros(1,Servernum);%统计每个边缘服务器上，缓存任务的rank值之和
for j=1:Servernum
    for i=1:Tasknum
        if(Cache(i,j) == 1) %服务器j缓存了任务i
            Serverranksum(j) = Serverranksum(j) + rank_combine(i);
        end
    end
end

for i=1:Tasknum
    if(Cachestatus(i) == 0)
        TaskComputationSpeed(i) = 0;
    elseif Cachestatus(i) == 1
        TaskComputationSpeed(i) = ComputeSpeed_server(Cachelocation(i));
    else 
        serverIndex = Cachelocation(i);
        TaskComputationSpeed(i) = ComputeSpeed_server(serverIndex) * (rank_combine(i)/Serverranksum(serverIndex));
    end
end

%计算资策略和缓存策略都做好了之后，时间还是得按照存在边的情况来计算服务延迟
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

% %再次求每种类型任务的计算时间
% for i=1:Tasknum
%     if Cachestatus(i) == 0 %如果在本地执行，计算时间就是之前计算出来的时间 不变
%         continue;
%     else
%         B= -1;%任务i的计算量
%         for k=1:userNum
%             if Taskgraph(i,i,k) ~= 0
%                 B = Taskgraph(i,i,k);
%                 break;
%             end
%         end
%         
%         TaskTime(i) = 1/((TaskComputationSpeed(i)/B) - Possionrate_sum(i));
%     end
% end
%     
% 
% Finishtime = zeros(1,userNum); %每个用户任务完成时间，就是这个用户的几种任务类型中，计算时间最长的那个
% for k = 1:userNum
%     for i = 1:Tasknum
%         if Taskgraph(i,i,k) ~= 0
%             if Finishtime(k) < TaskTime(i)
%                 Finishtime(k) = TaskTime(i);
%             end
%         end
%     end
% end
% 
% AvgFinishtime = 0;
% for i=1:userNum
%     AvgFinishtime = AvgFinishtime + Finishtime(i)*Possionrate(i)/Possionrate_total;
% end
          


end

