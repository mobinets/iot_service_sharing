function [rs] =Cal_ComputetimeLocal(index,userNum,Possionrate,Possionrate_sum,Computespeed_Local,Taskgraph)
%计算rank的过程中，计算第index种任务的本地处理时间。是一个在各个本地CPU上处理时间的加权平均值

rs = 0;
for i=1:userNum %分别计算在每个DAG中的时间
    if(Taskgraph(index, index, i) == 0)
        continue;
    end
    
    r = Computespeed_Local(index,i); %第i个本地CPU对第index种任务的本地处理速度
    B = Taskgraph(index,index,i); %第i个DAG中，第index种类型任务计算量。注意所有包含这种类型任务的DAG中，第index种类型任务计算量都一样
    time = 1/(r/B - Possionrate(i));
    
    rs = rs + (Possionrate(i)/Possionrate_sum(index)) * time;  %Possionrate(i)第i个DAG中任务index的泊松参数
end
    
end

