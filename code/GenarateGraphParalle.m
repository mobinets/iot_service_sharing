function [Graph] = GenarateGraphParalle(Tasknum,const)
%生成不同并行度的拓扑（合成后的DAG）：生成DAG的逻辑是，生成合成后的DAG，然后调用GenarateCommon_2生成各用户DAG，
%   然后再调用FulFillTaskGraph，给每个点和边权重值

%先生成合成之后的DAG，因此所有点都存在
%这个函数的输出，对于每个单独DAG，每个子任务类型都随机一下存在/不存在，得到多个用户的DAG即可

%只得到拓扑结构，Graph(i,i) = 1，Graph(i,j) = 1/-1表示这条边存在，Graph(i,j)=0表示没有这条边
%具体每个点和边的权重另外赋值

%const表示并行度，范围1~(Tasknum-2)，为1表示全部串行，为Tasknum-2表示出了收尾子任务外全部并行

Graph = zeros(Tasknum,Tasknum);
for i = 1:Tasknum
    Graph(i,i) = 1; %合成的DAG中，所有任务都存在
end

parameter = Tasknum - 2 - const; % 前面tasknum - 1 - const个任务串行 
for i =1:parameter
    Graph(i,i + 1) = 1;
    Graph(i+1,i) = -1;
end

parameter = parameter +1;
for i = (parameter + 1) : (Tasknum - 1) %这部分任务全部并行
    Graph(parameter,i) = 1;
    Graph(i,parameter) = -1;
    Graph(i,Tasknum) = 1;
    Graph(Tasknum,i) = -1;
end

    
    
end

