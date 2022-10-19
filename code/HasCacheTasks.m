function [hasCached] = HasCacheTasks(index,Cache,Tasknum,Servernum)
%除了边缘服务器index以外的其他服务器缓存了哪些任务
%返回一个1*Tasknum的矩阵，hasCached(i) == 1表示任务i已经被除index服务器以外的服务器缓存

hasCached = zeros(1,Tasknum);

for j=1:Servernum
    for i=1:Tasknum
        if(j == index)
            continue;
        end
        
        if(Cache(i,j) == 1)
            hasCached(i)=1;
        end
    end
end
            

end

