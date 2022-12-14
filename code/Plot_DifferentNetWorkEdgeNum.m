%Plot_DifferentNetWorkEdgeNum
%GenerateData_Network第一个参数：服务器之间的边数不同
%最后论文用了这个参数画出来的图 Network Connectivity ，服务器数量固定，平均每个服务器连通度（边数）变化

% userNum = 50;
% Servernum = 30; %最多30 * 29/2，是服务器数量的14.5倍
% Tasknum = 100;
% 
% ration = [2,5,8,10,12,14];
userNum = 1;
Servernum = 8; %最多30 * 29/2，是服务器数量的14.5倍
Tasknum = 20;

ration = [1,1.5,2,2.5,3];

len = length(ration);

Graph = GenarateGraphParalle(Tasknum,round(Tasknum*0.4));%并行度
% [Taskgraph,Graph] = GenarateGraphCommon_2(Graph,Tasknum,userNum,0.3); %相似任务占比0.3
    % 这里设置userNum为1，直接给Taskgraph赋值就行了
    Taskgraph = zeros(Tasknum,Tasknum,userNum);
    Taskgraph(:,:,1) = Graph;
    

[ServerMemory,TaskMemory,Possionrate,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server,EdgeWeight,TaskSize] = GenerateData_NetworkConnect(round(Servernum*(Servernum-1)/4),userNum,Servernum,Tasknum);
Taskgraph = FulFillTaskgraph(Taskgraph,EdgeWeight,TaskSize,userNum,Tasknum);

for j = 1 : userNum
        [~, ~] = countTaskLayer(Taskgraph(:,:,j),Tasknum,1,1,j);
end

taskset = randperm(Tasknum,Tasknum);

for k=1:len
    
    edgeNum = Servernum * ration(k);
    
   for times = 1:20
    
    
    %edgeNum改变，其他参数不变
    Transferrate_network = Transferrate;


%----------------添加代码，网络连通性（边缘服务器之间有的能连通，有的不能连通，一共edgeNum条边）---------------------------------------
    NetworkTopo = zeros(Servernum, Servernum);

    n = Servernum;
    rowLast = zeros(1,n - 1);
    rowLast(1) = n-1;
    for i=2:(n - 1)
        rowLast(i) = rowLast(i-1) + n-i;
    end

    MAX_EDGE_NUM = n * (n - 1)/2;
%右上半部分（不包含中间斜线）共n*(n-1)/2个点，第一行点数(n-1)，第n-1行点数1。分别编号为1 ~ n*(n-1)/2
    edgeset = randperm(MAX_EDGE_NUM,edgeNum); %从1~n * (n - 1)/2中，随机选出edgeNum个数

    for index = 1:edgeNum
    %分别找到edgeset(index)代表所在行和列下标，在这里添加一条边
        row = 1;
        while edgeset(index) > rowLast(row)
            row = row + 1;
        end
    
    %第row行共有Tasknum - row个点
        col = n - (rowLast(row) - edgeset(index));
    
        NetworkTopo(row, col) = 1;
        NetworkTopo(col, row) = 1;
    end

    for i=1:Servernum
        for j=1:Servernum
            if i==j
                continue;
            end
        
            if NetworkTopo(i,j) == 0
                Transferrate_network(i,j) = Transferrate_network(i,j) * NetworkTopo(i,j); %NetworkTopo(i,j)为1，这两个服务器才连通，为0的话不连通
            end
        
        end
    end
    
    
    
    
    
    
    
    
   
    [preCache_p3,preTaskComputationSpeed_p3,preFinishTime_p3] = P3_network(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
    
    %[preCache_iwqos,preTaskComputationSpeed_iwqos,preFinishTime_iwqos] = P1_iwqos_network(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
    [preCache_iwqos2,preTaskComputationSpeed_iwqos2,preFinishTime_iwqos2] = P1_iwqos_network_taskset(taskset,Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
    
    
    [preCache_infocom,preTaskComputationSpeed_infocom,preFinishTime_infocom] = P1_infocom_network(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);

    [~,~,preFinishTime_best] = P1_IterateNum_network(5000,Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
    
     ration(k)
%     y(k) = preFinishTime_p3;
%     y2(k) = preFinishTime_infocom;
%     y3(k) = preFinishTime_iwqos2;
%     y4(k) = preFinishTime_best;
    
         z(k,times) = preFinishTime_p3;
        z2(k,times) = preFinishTime_infocom;
        z3(k,times) = preFinishTime_iwqos2;
        z4(k,times) = preFinishTime_best;
        
    end 
end

for i = 1 : len
    y(i) = mean(z(i,:));
    y2(i) = mean(z2(i,:));
    y3(i) = mean(z3(i,:));
    y4(i) = mean(z4(i,:));
end

hold on;
plot(ration,y4);
plot(ration,y);
plot(ration,y2);
plot(ration,y3);

