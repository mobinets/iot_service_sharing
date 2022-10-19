function [preCache,preTaskComputationSpeed,preFinishTime] = P_best_network(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server)



%合成的DAG中每种类型子任务最终的泊松到达参数和
Possionrate_sum = zeros(1,Tasknum);
for j=1:userNum
    for i=1:Tasknum
        if Taskgraph(i,i,j) ~= 0
            Possionrate_sum(i) = Possionrate_sum(i) + Possionrate(j);
        end
    end
end


preCache = zeros(Tasknum,Servernum);
preTaskComputationSpeed = zeros(1,Tasknum);

Cache =  zeros(Tasknum,Servernum);
preFinishTime =  Best_Recursion_network(1,Cache,Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server,Possionrate_sum);




