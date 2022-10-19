function [finishTime] = Best_Recursion_network(taskIndex,Cache,Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server,Possionrate_sum)
%Cache表示缓存情况，是一个Tasknum*Servernum的矩阵，Cache(i,j)==1/0表示server j缓存/没缓存任务i
if taskIndex == Tasknum + 1
    [~,finishTime] = P2_network(Tasknum,userNum,Servernum,Cache,Possionrate,Possionrate_sum,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
    return;
end


%taskIndex不缓存
finishTime = Best_Recursion_network(taskIndex + 1,Cache,Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server,Possionrate_sum);

%taskIndex依次尝试缓存到服务器1~Servernum
for serverIndex = 1 : Servernum
    if ServerMemory(serverIndex) < TaskMemory(taskIndex)
        continue;
    end
    
    Cache(taskIndex, serverIndex) = 1;
    ServerMemory(serverIndex) = ServerMemory(serverIndex) - TaskMemory(taskIndex);
    tempFinishTime = Best_Recursion_network(taskIndex + 1,Cache,Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server,Possionrate_sum);
    
    if tempFinishTime < finishTime
        finishTime = tempFinishTime;
    end
    
    %回溯
     Cache(taskIndex, serverIndex) = 0;
     ServerMemory(serverIndex) = ServerMemory(serverIndex) + TaskMemory(taskIndex);
    
end



