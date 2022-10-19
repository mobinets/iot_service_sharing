function [Graph] = GenarateGraph_DifferentEdgeNum(Tasknum,edgeNum)
%这个函数是专门为 DAG复杂度（DAG中边的数量与点的数量比值）实验写的
%生成一个点数为Tasknum、边数为edgeNum的DAG

%生成Graph，edgeNum是边的数量
%边的数量最多为,n*(n-1)/2

Graph = zeros(Tasknum,Tasknum);
for i = 1:Tasknum
    Graph(i,i) = 1; %合成的DAG中，所有任务都存在
end

rowLast = zeros(1,Tasknum - 1);
rowLast(1) = Tasknum-1;
for i=2:(Tasknum - 1)
    rowLast(i) = rowLast(i-1) + Tasknum-i;
end

MAX_EDGE_NUM = Tasknum * (Tasknum - 1)/2;
%右上半部分（不包含中间斜线）共n*(n-1)/2个点，第一行点数(n-1)，第n-1行点数1。分别编号为1 ~ n*(n-1)/2
edgeset = randperm(MAX_EDGE_NUM,edgeNum); %从1~Tasknum * (Tasknum - 1)/2中，随机选出edgeNum个数

for index = 1:edgeNum
    %分别找到edgeset(index)代表所在行和列下标，在这里添加一条边
    row = 1;
    while edgeset(index) > rowLast(row)
        row = row + 1;
    end
    
    %第row行共有Tasknum - row个点
    col = Tasknum - (rowLast(row) - edgeset(index));
    
    Graph(row, col) = 1;
end


%对称矩阵，处理左下角
for i = 2:Tasknum
    for j=1:(i-1)
        Graph(i,j) = -Graph(j,i);
    end
end

end

