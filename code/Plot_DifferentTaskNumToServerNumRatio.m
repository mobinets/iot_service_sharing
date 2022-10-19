%Plot_DifferentTaskNumToServerNumRatio
%Tasknum DAG中子任务数量 与 服务器数量的比值
%最后论文中使用了这个图

% userNum = 20;
% Servernum = 5;%服务器数量固定为2，子任务数量变化
% Ration = [10,20,40,60,80,100];

userNum = 4;
Servernum = 4;%服务器数量固定为2，子任务数量变化
Ration = [1,2,4,6,8,10];

Tasknum_max = max(Ration) * Servernum; %500
Tasknum_min = min(Ration) * Servernum;%50
Tasknum_mean = round((Tasknum_max + Tasknum_min)/2);

[ServerMemory,TaskMemory,Possionrate,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server,EdgeWeight,TaskSize] = GenerateData_NetworkConnect(round(Servernum*(Servernum-1)/4),userNum,Servernum,Tasknum_mean);

%下面几个变量的length与Tasknum有关，应该按照Tasknum_max来设置
TaskMemory = randi([20 80],1,Tasknum_max);
Computespeed_Local = 3 + 2*rand(Tasknum_max,userNum);

EdgeWeight = zeros(Tasknum_max,Tasknum_max);
for i = 1:(Tasknum_max-1)
    for j=(i+1):Tasknum_max
        EdgeWeight(i,j) = randi([16 32]);
    end
end

TaskSize =  randi([10 30],1,Tasknum_max);


len = length(Ration(:));
for i=1:len
    Tasknum = Ration(i) * Servernum;
    
    for times = 1 : 20
     Graph = GenarateGraphParalle(Tasknum,round(Tasknum*0.4));%并行度
     [Taskgraph,Graph] = GenarateGraphCommon_2(Graph,Tasknum,userNum,0.3); %相似任务占比0.3
%      %这里设置userNum为1，直接给Taskgraph赋值就行了
%      Taskgraph = zeros(Tasknum,Tasknum,userNum);
%      Taskgraph(:,:,1) = Graph;
     
     Taskgraph = FulFillTaskgraph(Taskgraph,EdgeWeight,TaskSize,userNum,Tasknum);
     for j = 1 : userNum
        [~, ~] = countTaskLayer(Taskgraph(:,:,j),Tasknum,times,Ration(i),j);
    end
     
     %[preCache,preTaskComputationSpeed,preFinishTime] = P1_RankOnNum(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Computespeed_Local,ComputeSpeed_server);
    [preCache_p3,preTaskComputationSpeed_p3,preFinishTime_p3] = P3_network(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
     
    %[preCache_infocom,preTaskComputationSpeed_infocom,preFinishTime_infocom] = P1_infocom(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Computespeed_Local,ComputeSpeed_server);
    %[preCache_iwqos,preTaskComputationSpeed_iwqos,preFinishTime_iwqos] = P1_iwqos(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Computespeed_Local,ComputeSpeed_server);
    [preCache_iwqos,preTaskComputationSpeed_iwqos,preFinishTime_iwqos] = P1_iwqos_network(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
    
    
    %[preCache_infocom2,preTaskComputationSpeed_infocom2,preFinishTime_infocom2] = Copy_of_P1_infocom(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Computespeed_Local,ComputeSpeed_server);
    [preCache_infocom,preTaskComputationSpeed_infocom,preFinishTime_infocom] = P1_infocom_network(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
    
     [~,~,preFinishTime_best] = P1_IterateNum_network(3000,Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
    
    
    Ration(i)
    
%     y(i) = preFinishTime_p3;
%     y2(i) = preFinishTime_infocom;
%     y3(i) = preFinishTime_iwqos;
%     y4(i) = preFinishTime_best;
    
        z(i,times) = preFinishTime_p3;
        z2(i,times) = preFinishTime_infocom;
        z3(i,times) = preFinishTime_iwqos;
        z4(i,times) = preFinishTime_best;
    end
end

for i = 1 : length(Ration)
    y(i) = mean(z(i,:));
    y2(i) = mean(z2(i,:));
    y3(i) = mean(z3(i,:));
    y4(i) = mean(z4(i,:));
end

hold on;
plot(Ration,y4);%best
plot(Ration,y);
plot(Ration,y2);%ICE
plot(Ration,y3);

