%Plot_DifferentNetWorkEdgeNum_finishtime  2021.7.25加的实验
%与实验Plot_DifferentNetWorkEdgeNum的纵轴不同，纵轴为完成时间小于某个值的user任务数量。调用的是P3_network_addFinishtime,该函数返回的第四个参数是每个dag任务的实际完成时间
%给一个时间阈值
threshold = 0;%时间阈值根据跑出来的结果中，耗时最长的任务来决定


%GenerateData_Network第一个参数：服务器之间的边数不同
%最后论文用了这个参数画出来的图 Network Connectivity ，服务器数量固定，平均每个服务器连通度（边数）变化

% userNum = 50;
% Servernum = 30; %最多30 * 29/2，是服务器数量的14.5倍
% Tasknum = 100;
% ration = [2,5,8,10,12,14];
userNum = 25;
Servernum = 8; %最多30 * 29/2，是服务器数量的14.5倍
Tasknum = 35;
ration = [1,1.5,2,2.5,3];

len = length(ration);

Graph = GenarateGraphParalle(Tasknum,round(Tasknum*0.4));%并行度
[Taskgraph,Graph] = GenarateGraphCommon_2(Graph,Tasknum,userNum,0.3); %相似任务占比0.3


[ServerMemory,TaskMemory,Possionrate,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server,EdgeWeight,TaskSize] = GenerateData_NetworkConnect(round(Servernum*(Servernum-1)/4),userNum,Servernum,Tasknum);
Taskgraph = FulFillTaskgraph(Taskgraph,EdgeWeight,TaskSize,userNum,Tasknum);

taskset = randperm(Tasknum,Tasknum);

y_a = zeros(1, len);
y2_a = zeros(1, len);
y3_a = zeros(1,len);
y4_a = zeros(1, len);

maxtime = 20;
for times = 1 : maxtime%注意！！！！这里做了重复试验，结果需要除以次数


%for k=1:len
for k=len:-1:1%从大往小取
    
%     for kk = 1:20
    
    edgeNum = Servernum * ration(k);
    
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
    
    
    
    [~,~,~, taskFinishTime_best] =  P1_IterateNum_network_addFinishtime(10000, Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
    
      %动态更新threshold时间阈值
    if k==len
        threshold = max(taskFinishTime_best);
    end

    
    count4 = 0;
    for index = 1:userNum
        if taskFinishTime_best(index) <= threshold
            count4 = count4 + 1;
        end
    end
    y4_a(k) = y4_a(k)+count4;
    
    
   
    [preCache_p3,preTaskComputationSpeed_p3,preFinishTime_p3, taskFinishTime_p3] = P3_network_addFinishtime(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
    
%     %动态更新threshold时间阈值
%     if k==len
%         threshold = max(taskFinishTime_p3);
%     end
    
    count = 0;
    for index = 1:userNum
        if taskFinishTime_p3(index) <= threshold
            count = count + 1;
        end
    end
    y_a(k) = y_a(k)+ count;
    
    %%[preCache_iwqos,preTaskComputationSpeed_iwqos,preFinishTime_iwqos] = P1_iwqos_network(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
    [preCache_iwqos2,preTaskComputationSpeed_iwqos2,preFinishTime_iwqos2, taskFinishTime_iwqos2] = P1_iwqos_network_taskset_addFinishtime(taskset,Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
    count3 = 0;
    for index = 1:userNum
        if taskFinishTime_iwqos2(index) <= threshold
            count3 = count3 + 1;
        end
    end
    y3_a(k) = y3_a(k) + count3;
    
    [preCache_infocom,preTaskComputationSpeed_infocom,preFinishTime_infocom, taskFinishTime_infocom] = P1_infocom_network_addFinishtime(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
    count2 = 0;
    for index = 1:userNum
        if taskFinishTime_infocom(index) <= threshold
            count2 = count2 + 1;
        end
    end
    y2_a(k) = y2_a(k)+count2;
    
 
    
    
    
    %ration(k)
    %y(k) = preFinishTime_p3;
    %y2(k) = preFinishTime_infocom;
    %%y3(k) = preFinishTime_iwqos;
    %y4(k) = preFinishTime_iwqos2;
    

end

times

end

%由于做了maxtimes组重复试验，结果需要除以maxtimes
y_a = y_a/maxtime;
y2_a = y2_a/maxtime;
y3_a = y3_a/maxtime;
y4_a = y4_a/maxtime;

hold on;
plot(ration, y4_a);
plot(ration, y_a);
plot(ration, y2_a);
plot(ration, y3_a);

%plot(ration,y);
%hold on;
%plot(ration,y2);
%%plot(ration,y3);
%plot(ration,y4);
