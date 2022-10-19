function [rs] = ComputationSpeedAllocation(rank_combine,Cache,Cachelocation,Cachestatus,Tasknum,Servernum,ComputeSpeed_server)
%根据rank_combine值比例，划分Cachestatus == 2的任务的计算资源（对应服务器上的计算速度）

%统计每个边缘服务器上，缓存任务的rank值之和
Serverranksum = zeros(1,Servernum);
for j=1:Servernum
    for i=1:Tasknum
        if(Cache(i,j) == 1) %服务器j缓存了任务i
            Serverranksum(j) = Serverranksum(j) + rank_combine(i);
        end
    end
end

rs = zeros(1,Tasknum);% rs(i)表示第i中任务在服务器上执行的速度
for i=1:Tasknum
    if(Cachestatus(i) == 0)
        rs(i) = 0;%任务i在本地计算，赋值0
    elseif(Cachestatus(i) == 1) %任务i不存在资源竞争，速度是对应服务器的最大计算速率
        rs(i) = ComputeSpeed_server(Cachelocation(i));
    else %存在资源竞争
        serverIndex = Cachelocation(i);
        rs(i) = ComputeSpeed_server(serverIndex) * (rank_combine(i)/Serverranksum(serverIndex));
    end
end

end

