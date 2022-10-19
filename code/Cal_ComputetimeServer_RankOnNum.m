function [rs] = Cal_ComputetimeServer_RankOnNum(index,Tasknum,userNum,Servernum,Cache,ComputeSpeed_server,Possionrate_sum,Taskgraph)
%计算rank的过程中，计算第index种任务的在被缓存的边缘服务器上的计算时间。注意现在运行速度是服务器最大速度 / 这台服务器缓存的任务数量

%哪台服务器缓存了第index种任务
serverindex = -1;
for i=1:Servernum
    if (Cache(index,i) == 1)
        serverindex = i;
        break;
    end
end

%看一下这台服务器缓存了几个任务
count = 0;
for i=1:Tasknum
    if Cache(i,serverindex) == 1
        count = count + 1;
    end
end

r = ComputeSpeed_server(serverindex);%这台服务器的最大计算速度
r = r/count;
B = -1;
for i=1:userNum
    if(Taskgraph(index,index,i) ~= 0)
        B = Taskgraph(index,index,i);%任务index的计算量
        break;
    end
end

rs = 1/(r/B - Possionrate_sum(index));
     
end

