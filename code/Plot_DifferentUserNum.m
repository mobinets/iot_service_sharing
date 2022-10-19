%Plot_DifferentUserNum 
%横轴是用户数量，其实是DAG种类数量，因为每个用户dag都不同。纵轴是加权平均延迟
%最后没用这个实验，用户数量的延迟好像说明不了什么事情


Servernum = 5;
Tasknum = 25;
userNumlist = [4, 8, 12,16, 20];

maxuserNum = max(userNumlist);%userNumlist的最大值

len = length(userNumlist);

maxtime = 20;
for times = 1:maxtime

Graph = GenarateGraphParalle(Tasknum,round(Tasknum*0.4));%并行度
[Taskgraph,Graph] = GenarateGraphCommon_2(Graph,Tasknum,maxuserNum,0.3); %相似任务占比0.3

[ServerMemory,TaskMemory,Possionrate,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server,EdgeWeight,TaskSize] = GenerateData_NetworkConnect(round(Servernum*(Servernum-1)/4),maxuserNum,Servernum,Tasknum);
Taskgraph = FulFillTaskgraph(Taskgraph,EdgeWeight,TaskSize,maxuserNum,Tasknum);



for k= 1: len
    userNum = userNumlist(k);
    
    [preCache_p3,preTaskComputationSpeed_p3,preFinishTime_p3, taskFinishTime_p3] = P3_network_addFinishtime(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
    
    [preCache_iwqos,preTaskComputationSpeed_iwqos,preFinishTime_iwqos, taskFinishTime_iwqos] = P1_iwqos_network_addFinishtime(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
    
    [preCache_infocom,preTaskComputationSpeed_infocom,preFinishTime_infocom, taskFinishTime_infocom] = P1_infocom_network_addFinishtime(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
   
    [~,~,preFinishTime_best, taskFinishTime_best] =  P1_IterateNum_network_addFinishtime(7000, Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
    
    
        z(k,times) = preFinishTime_p3;
        z2(k,times) = preFinishTime_infocom;
        z3(k,times) = preFinishTime_iwqos;
        z4(k,times) = preFinishTime_best;
    
end

times

end

for i = 1 : len
    y(i) = mean(z(i,:));
    y2(i) = mean(z2(i,:));
    y3(i) = mean(z3(i,:));
    y4(i) = mean(z4(i,:));
end

hold on;
plot(userNumlist,y4);%best
plot(userNumlist,y);
plot(userNumlist,y2);%ICE
plot(userNumlist,y3);

   