function [rs] = Cal_Communicationtime(Taskgraph_finally,Transferrate,Cachelocation,Tasknum,userNum,Servernum,Taskgraph,Possionrate,Possionrate_sum)
%现在Taskgraph_finally(i,j)是任务i、j之间传输数据量，要计算任务i、j之间通信时间
%注意如果任务i、j都在本地执行，或者在同一服务器执行，那么通信时间设为0.0001（不要设置为0！会认为没有这条边）

rs = Taskgraph_finally;

for i=1:(Tasknum-1)
    for j=(i+1):Tasknum
        if rs(i,j) == 0
            continue;
        end
        
        %先判断任务i、任务j处理的服务器的情况
        locali = Cachelocation(i);
        localj = Cachelocation(j);
        
        if(locali == localj) %如果两个都在本地执行，或者在同一个边缘服务器执行，那么通信时间为0
            rs(i,j) = 0.0001;
        elseif (locali ~= 0 && localj~=0) %两个任务在不同的边缘服务器上执行
            rs(i,j) = rs(i,j)/Transferrate(locali,localj); %任务之间通信量 / 两个服务器间的通信速度
        elseif locali == 0 %任务i在本地执行，任务j在边缘服务器上执行
            temp = 0;
            for k=1:userNum
                if(Taskgraph(i,i,k) == 0)
                    continue;
                end
                
                temp = temp + (rs(i,j)/Transferrate(Servernum+k, localj)) * Possionrate(k)/Possionrate_sum(i);
            end
            rs(i,j) = temp;
        else % 任务i在边缘服务器执行，任务j在本地执行
            temp = 0;
            for k=1:userNum
                if(Taskgraph(j,j,k) == 0)
                    continue;
                end
                
                temp = temp + (rs(i,j)/Transferrate(locali,Servernum+k)) * Possionrate(k)/Possionrate_sum(j);
            end
            rs(i,j) = temp;
        end
        
    end
end

for i=2:Tasknum
    for j=1:(i-1)
        rs(i,j) = -rs(j,i);
    end
end
                    
end

