function [Taskgraph] = FulFillTaskgraph(Taskgraph,EdgeWeight,TaskSize,userNum,Tasknum)
%输入的Taskgraph只表示拓扑，点和边的权重为1/-1/0。
%EdgeWeight,TaskSize是从GenerateData函数得到的输出，利用这两个数据完成Taskgraph中点和边的权重

%Taskgraph中各边的权重
for k=1:userNum 
    for i = 1:(Tasknum - 1)
        for j = (i+1):Tasknum
            Taskgraph(i,j,k) = Taskgraph(i,j,k) * EdgeWeight(i,j);
        end
    end
    
    for i = 2:Tasknum
        for j = 1:(i-1)
            Taskgraph(i,j,k) = - Taskgraph(j,i,k);
        end
    end
end

%边的权重
for k=1:userNum
    for i=1:Tasknum
        if Taskgraph(i,i,k) == 1
            Taskgraph(i,i,k) = TaskSize(i);
        end
    end
end

end

