function [Taskgraph,Graph] = GenarateGraphCommon(Graph,Tasknum,userNum,commonration)
%被GenarateGraphCommon_2代替了，该函数在用并查集解决生成的一个用户DAG中存在多个联通分支那段代码有bug，有时要报错


%得到不同相似程度的userNum个DAG（DAG之间相同类型子任务所占比例），注意userNum > 1，四舍五入公共任务数量大于0（否则报错）
%可以先调用GenarateGraphParalle函数，得到合成之后的DAG的拓扑，也就是这个函数的输入参数Graph
%调用这个函数之后，输入参数Graph可能会改变，并作为输出返回
%调用这个函数之后，应该给Taskgraph中各点和各边赋值

%（2021/1/11）这样的生成算法有个问题：一些用户DAG存在独立的任务
%（2021/1/11）解决了独立子任务，但是可能存在一些DAG中存在多个连通分支，但是P2函数计算不会有问题
%(2021/1/19) 使用并查集解决了一个用户DAG中可能存在多个连通分支的问题，添加了函数findRoot()

%Graph是合成之后的DAG关联矩阵
%commonration是相似百分比

Taskgraph = zeros(Tasknum,Tasknum,userNum); 
ContainTaskNum = zeros(1,userNum);%每个DAG中包含任务数量

commonnum = round(Tasknum * commonration);%相同类型子任务的个数，四舍五入
%从前Tasknum-1个任务中随机无重复选出commonnum-1个任务，这些任务至少存在于两个DAG中
tempCommontask = randperm(Tasknum - 1,commonnum-1);
%剩下的一个公共任务是第Tasknum个任务，这个任务存在于所有DAG中
commontask = zeros(1,Tasknum);
commontask(1) = Tasknum;
commontask(2:commonnum) = tempCommontask(1:(commonnum-1));

for i=1:userNum
    Taskgraph(Tasknum,Tasknum,i) = 1;%所有DAG中都存在第Tasknum个任务
end
ContainTaskNum(1:userNum) = 1;

for i=2:commonnum
    taskId = commontask(i);
    
    %至少有两个DAG中有这个类型任务，其他DAG中随机一下有/没有
    selectedUser = randperm(userNum,2); %随机选中两个用户DAG
    Taskgraph(taskId,taskId,selectedUser(1)) = 1;
    Taskgraph(taskId,taskId,selectedUser(2)) = 1;
    ContainTaskNum(selectedUser(1)) = ContainTaskNum(selectedUser(1)) + 1; %对应DAG包含的任务数量+1
    ContainTaskNum(selectedUser(2)) = ContainTaskNum(selectedUser(2)) + 1;
    
    for j = 1:userNum
        if Taskgraph(taskId,taskId,j) == 1
            continue;
        end
        
        isIn = randi(2,1,1); %随机选择数字1和2
        if isIn == 1
            Taskgraph(taskId,taskId,j) = 1;
            ContainTaskNum(j) =  ContainTaskNum(j) + 1;
        end
    end
end


%对于其他Tasknum - commonnum个任务，取1~userNum的随机数，这个任务只会出现在其中一个DAG中
for i = 1:Tasknum
    %如果任务i是公共任务，则continue
    isContain = false;
    for j = 1:commonnum
        if commontask(j) == i
            isContain = true;
            break;
        end
    end
    if isContain == true 
        continue;
    end
    
    index = randi(userNum,1,1); %随机从userNum个DAG中选择一个
    Taskgraph(i,i,index) = 1;
    ContainTaskNum(index) = ContainTaskNum(index) + 1;
end

%避免某个DAG中只存在一个任务
% for i=1:userNum
%     if ContainTaskNum(i) == 0
%         %从Tasknum个任务中，随机选择1~从Tasknum个任务中个任务，作为第i个DAG包含的任务
%         count =  randi(Tasknum,1,1);
%         tempTasks =  randperm(Tasknum,count);%1*count的数组
%         for k=1:count
%             tempTaskId = tempTasks(k);
%             Taskgraph(tempTaskId,tempTaskId,i) = 1;
%         end
%     end
% end


%至此所有DAG中分别有哪些任务已经确定了，下面根据分别有的任务，给边
for k = 1:userNum
    for i = 1:Tasknum
        for j=1:Tasknum
            if(i == j)
                continue;
            end
            
            if Taskgraph(i,i,k)==1 && Taskgraph(j,j,k)==1 %第k个DAG中存有任务i，又有任务j，这条边才会存在
                Taskgraph(i,j,k) = Graph(i,j);
            end
        end
    end
end

%解决生成的一些用户DAG中存在独立子任务的问题
for k = 1:userNum
    for i = 1:Tasknum
        if Taskgraph(i,i,k) == 0
            continue;
        end
        
        %判断这个子任务在当前DAG中是不是独立子任务
        flag = true;
        for j = 1:Tasknum
            if i == j
                continue;
            end
            
            if Taskgraph(i,j,k) ~= 0
                flag = false;
                break;
            end
        end
        
        if flag == true %如果发现当前DAG中的下标为i的任务是独立子任务，就要加边，把它变成非独立子任务
              pre = i - 1;
              next = i + 1;
              
              while pre >= 1 && Taskgraph(pre,pre,k)==0
                  pre = pre - 1;
              end
              if pre >= 1 %说明当前DAG中，任务i之前有序号更小的任务
                  Taskgraph(pre,i,k) = 1;
                  Taskgraph(i,pre,k) = -1;
                  Graph(pre,i) = 1;%合成的DAG也需要加上这条边
                  Graph(i,pre) = -1;
              end
              
              while next <= Tasknum && Taskgraph(next,next,k)==0
                  next = next + 1;
              end
              if next <= Tasknum
                  Taskgraph(i,next,k) = 1;
                  Taskgraph(next,i,k) = -1;
                  Graph(i,next) = 1;
                  Graph(next,i) = -1;
              end
              
        end
        
    end
 
end

%并查集，解决某些用户DAG中存在2个或以上连通分支的问题
for k=1:userNum
    f = zeros(1,Tasknum);
    size = ones(1,Tasknum);
    
    for i=1:Tasknum
        if Taskgraph(i,i,k) == 1 %如果第k个用户DAG存在任务i，那么初始化任务i的父节点为自身。如果不存在任务i，那么其父节点为0（根本就不存在任务0）
            f(i) = i;
        end
    end
    
    for i=1:Tasknum
        for j=1:Tasknum
            if i==j
                continue;
            end
            
            if Taskgraph(i,j,k) > 0 %只对>0的边操作，因为现在是有向图
                %union(i,j)
                [rooti,f] = findRoot(f,i);
                [rootj,f] = findRoot(f,j);
                
                if rooti ~= rootj
                    f(rootj) = f(rooti);
                    size(rooti) = size(rooti) + size(rootj);
                end
            end
        end
    end
    
    [root,f] = findRoot(f,Tasknum); %每个DAG都存在第Tasknum个任务
    if size(root) == ContainTaskNum(k) %只有一个连通分支
        continue;
    end
    
    %统计第k个用户DAG中有几个连通分支，把所有连通分支的根节点放在rootset中
    rootset(1) = root;
    index = 1;
    for i=1:Tasknum
        if Taskgraph(i,i,k) == 0
            continue;
        end
        
        [curRoot,f] = findRoot(f,i);
        if ismember(curRoot,rootset) == 0 %如果curRoot不在rootset数组中，则加入 rootset.add(curRoot)
            index = index + 1;
            rootset(index) = curRoot;
        end
    end
    
    %把rootset中第一个元素和最后一个元素交换位置，rootset就是有序了
    temp = rootset(1);
    rootset(1) = rootset(index);
    rootset(index) = temp;
    map = zeros(1,Tasknum); %每个连通分支的根节点在rootset中对应的下标位置 1~index
    for i=1:index
        map(rootset(i)) = i;
    end
    
    %找到每个连通分支并查集合中，下标最大的那个元素
    finalIndex = rootset;
    for i=1:Tasknum
        if Taskgraph(i,i,k) == 0
            continue;
        end
        
         [curRoot,f] = findRoot(f,i);
         if i > finalIndex(map(curRoot))
             finalIndex(map(curRoot)) = i;
         end
    end
    
    %添加边，让连通分支只有一个。上一个连通分支编号最大的点，连接下一个连通分支的根节点
    for j = 2:index
        Taskgraph(finalIndex(j-1),rootset(j),k) = 1;
        Taskgraph(rootset(j),finalIndex(j-1),k) = -1;
        Graph(finalIndex(j-1),rootset(j)) = 1;
        Graph(rootset(j),finalIndex(j-1)) = -1;
    end
    
end

end


