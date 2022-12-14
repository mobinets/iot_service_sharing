%不同的 服务器间通信速度。通信速度变化导致任务计算时间和通信时间比值变化   Plot_DifferentCommunicationRate
%最后论文中使用了这个函数画出来的图


% Tasknum = 100;
% Servernum = 10;
% userNum = 50;

Tasknum = 20; 
Servernum = 5; 
userNum = 1;

%得到拓扑
Graph = GenarateGraphParalle(Tasknum,round(Tasknum*0.4)); %并行度
%[Taskgraph,Graph] = GenarateGraphCommon_2(Graph,Tasknum,userNum,0.3); %相似任务占比0.3
% 这里设置userNum为1，直接给Taskgraph赋值就行了
   Taskgraph = zeros(Tasknum,Tasknum,userNum);
   Taskgraph(:,:,1) = Graph;

%edgeNum固定为Servernum*(Servernum-1)/4
[ServerMemory,TaskMemory,Possionrate,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server,EdgeWeight,TaskSize] = GenerateData_NetworkConnect(round(Servernum*(Servernum-1)/4),userNum,Servernum,Tasknum);

Taskgraph_cur = FulFillTaskgraph(Taskgraph,EdgeWeight,TaskSize,userNum,Tasknum);



%GenerateData中服务器间通信速度 (4,6)
ration = [0.1,0.3,0.5,1,1.5];
[~,length] = size(ration);
for k=1:length
    for times = 1:20
%     curR = ration(k);
%     low = 2*curR;
%     high = 8*curR;
%     
%     EdgeWeight = zeros(Tasknum,Tasknum);
%     for i = 1:(Tasknum-1)
%         for j=(i+1):Tasknum
%             EdgeWeight(i,j) = randi([low high]);
%         end
%     end
    
    curR = ration(k);
    low = 4*curR;
    high = 6*curR;
    
    Transferrate = low + (high - low)*rand(Servernum+userNum,Servernum+userNum); %这应该是个对称矩阵
    for i=2:(Servernum+userNum)
        for j = 1:(i-1)
            Transferrate(i,j) = Transferrate(j,i);
        end
    end
    

    for j = 1 : userNum
        [~, ~] = countTaskLayer(Taskgraph_cur(:,:,j),Tasknum,times,ration(k),j);
    end

    %Taskgraph_cur = FulFillTaskgraph(Taskgraph,EdgeWeight,TaskSize,userNum,Tasknum);
    %[preCache,preTaskComputationSpeed,preFinishTime] = P1_RankOnNum(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph_cur,Transferrate,Computespeed_Local,ComputeSpeed_server);
    [preCache_p3,preTaskComputationSpeed_p3,preFinishTime_p3] = P3_network(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph_cur,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
    
    
    %[preCache_infocom,preTaskComputationSpeed_infocom,preFinishTime_infocom] = P1_infocom(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph_cur,Transferrate,Computespeed_Local,ComputeSpeed_server);
    %[preCache_iwqos,preTaskComputationSpeed_iwqos,preFinishTime_iwqos] = P1_iwqos(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph_cur,Transferrate,Computespeed_Local,ComputeSpeed_server);
    [preCache_iwqos,preTaskComputationSpeed_iwqos,preFinishTime_iwqos] = P1_iwqos_network(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph_cur,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
    
    
    %[preCache_infocom2,preTaskComputationSpeed_infocom2,preFinishTime_infocom2] = Copy_of_P1_infocom(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph_cur,Transferrate,Computespeed_Local,ComputeSpeed_server);
    [preCache_infocom,preTaskComputationSpeed_infocom,preFinishTime_infocom] = P1_infocom_network(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph_cur,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
    
     [~,~,preFinishTime_best] = P1_IterateNum_network(3000,Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph_cur,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
    
    
    curR
%     y(k) = preFinishTime_p3;
%     y2(k) = preFinishTime_infocom;
%     y3(k) = preFinishTime_iwqos;
         z(k,times) = preFinishTime_p3;
        z2(k,times) = preFinishTime_infocom;
        z3(k,times) = preFinishTime_iwqos;
        z4(k,times) = preFinishTime_best;
    
 
    end
end

for i = 1 : length
    y(i) = mean(z(i,:));
    y2(i) = mean(z2(i,:));
    y3(i) = mean(z3(i,:));
    y4(i) = mean(z4(i,:));
end

zz(1:length) = ration(1:length) * 5;

% plot(ration,y);
% hold on;
% %plot(ration,y2);
% plot(ration,y4);
% plot(ration,y3);

hold on;
plot(zz,y4(1:length));
plot(zz,y(1:length));
plot(zz,y2(1:length));
plot(zz,y3(1:length));


