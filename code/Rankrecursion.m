function [Rank] = Rankrecursion(Taskgraph,Tasknum, i)
%递归计算某个任务的rank值

MAX = 0;
for j=1:Tasknum
    if i == j
        continue;
    end
    if Taskgraph(j,j) == 0
        continue;
    end
    if Taskgraph(i,j) == 0
        continue;
    end
    
    if Taskgraph(i,j) > 0 % >0表示i到j的边，<0表示j到i的边
        temp = Rankrecursion(Taskgraph,Tasknum,j) + Taskgraph(i,j);
        if (MAX < temp)
            MAX = temp;
        end
    end
end

Rank = Taskgraph(i,i) + MAX;
end

