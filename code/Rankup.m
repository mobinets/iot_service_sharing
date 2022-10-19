function [Rank] = Rankup(Taskgraph,Tasknum)
%输入一个DAG，计算这个DAG的各任务rank值
%最终的rank值是多个DAG中得到的rank的加权平均，这个函数只是算出某个DAG中各任务的rank

%Taskgraph是一个Tasknum * Tasknum的矩阵，如果该DAG没有任务i，那么Taskgraph(i,i) = 0

Rank = zeros(1, Tasknum);
for i=1:Tasknum
    if Taskgraph(i,i) == 0
        Rank(1,i) = 0; %如果当前DAG中没有任务i，那么其rank值为0
        continue;
    end
    
    Rank(1,i) = Rankrecursion(Taskgraph,Tasknum, i);
end
end

