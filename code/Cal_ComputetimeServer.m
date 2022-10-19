function [rs] = Cal_ComputetimeServer(index,userNum,Servernum,Cache,ComputeSpeed_server,Possionrate_sum,Taskgraph)
%计算rank的过程中，计算第index种任务的在被缓存的边缘服务器上的计算时间。注意现在是以边缘服务器的最大速度运行

%哪台服务器缓存了第index种任务
serverindex = -1;
for i=1:Servernum
    if (Cache(index,i) == 1)
        serverindex = i;
        break;
    end
end

r = ComputeSpeed_server(serverindex);%这台服务器的最大计算速度
B = -1;
for i=1:userNum
    if(Taskgraph(index,index,i) ~= 0)
        B = Taskgraph(index,index,i);%任务index的计算量
        break;
    end
end

rs = 1/(r/B - Possionrate_sum(index));
     
end

