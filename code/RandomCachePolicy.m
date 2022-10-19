function [rs] = RandomCachePolicy(index,hasCached,ServerMemory,TaskMemory,Tasknum)
%为边缘服务器index随机选择一个满足条件的缓存策略

%hasCached(i) == 1表示任务i被其他边缘服务器缓存了
%ServerMemory(index)表示该边缘服务器的内存大小
%TaskMemory(i)表示缓存第i种类型任务所需的内存大小

rs = zeros(1,Tasknum);
memorySize = ServerMemory(index);%剩余内存容量
hasVisited = hasCached;

count=0;%统计已经被缓存了的任务数量
for i=1:Tasknum
    if(hasCached(i) == 1)
        count = count+1;
    end
end

while count < Tasknum
    taskId =  randi(Tasknum,1,1);%随机选择一个任务
    if(hasVisited(taskId) == 1) %选到已经尝试过，或者被其他服务器缓存了的任务，就continue
        continue;
    end
    
    flag = randi(2,1,1); %生成一个1~2的均匀分布随机数，如果为1，表示准备缓存，如果是2，就不缓存了
    if(flag == 1) %想要缓存，但是还得看看内存还够不够
        if(memorySize >= TaskMemory(taskId))
            rs(taskId) = 1;
            memorySize = memorySize - TaskMemory(taskId);
        end 
    end
    
    %不管缓不缓存，第taskId这个任务已经尝试过了
    hasVisited(taskId) = 1;
    count = count + 1;
        
end


end

