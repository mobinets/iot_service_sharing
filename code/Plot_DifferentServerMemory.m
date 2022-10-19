%服务器数量固定，但是服务器的memory变化，导致能够被cache的任务数量改变
%Plot_DifferentServerMemory
%论文没用这个图，但是毕设可以考虑。注意这里使用的还是P1，而不是P3

Tasknum = 10;
Servernum = 2;
userNum = 1;

%得到拓扑
Graph = GenarateGraphParalle(Tasknum,round(Tasknum*0.4)); %并行度
%[Taskgraph,Graph] = GenarateGraphCommon_2(Graph,Tasknum,userNum,0.3); %相似任务占比0.3
% 这里设置userNum为1，直接给Taskgraph赋值就行了
Taskgraph = zeros(Tasknum,Tasknum,userNum);
Taskgraph(:,:,1) = Graph;

%其他数据都不变，但ServerMemory是变量
[ServerMemory,TaskMemory,Possionrate,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server,EdgeWeight,TaskSize] = GenerateData_NetworkConnect(round(Servernum*(Servernum-1)/4),userNum,Servernum,Tasknum);
%GenerateData函数中TaskMemory的范围是[20,80]，方差太大了，改小一点
TaskMemory = randi([40 60],1,Tasknum);


Taskgraph = FulFillTaskgraph(Taskgraph,EdgeWeight,TaskSize,userNum,Tasknum);


ration = [0.2,0.4,0.6,0.8,1];
%  x = 0:2:28;
for k=1:length(ration)
for times = 1:30
    cacheNum = Tasknum * ration(k);
    %ServerMemory = normrnd(cacheNum/2 * 50 + 25,1,[1 Servernum]);
    ServerMemory =  normrnd(cacheNum/Servernum * 50 + 25,1,[1 Servernum]);
    
    [preCache_p3,preTaskComputationSpeed_p3,preFinishTime_p3] = P3_network(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
    
    [preCache_iwqos,preTaskComputationSpeed_iwqos,preFinishTime_iwqos] = P1_iwqos_network(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
    
    [preCache_infocom,preTaskComputationSpeed_infocom,preFinishTime_infocom] = P1_infocom_network(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
    
     [~,~,preFinishTime_best] = P1_IterateNum_network(7000,Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
    
    
    ration(k)
%     y(k) = preFinishTime_p3;
%     y2(k) = preFinishTime_infocom;
%     y3(k) = preFinishTime_iwqos;
         z(k,times) = preFinishTime_p3;
        z2(k,times) = preFinishTime_infocom;
        z3(k,times) = preFinishTime_iwqos;
        z4(k,times) = preFinishTime_best;
    
    
end
end

for i = 1 : length(ration)
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


