%两个阿里数据集中DAG的例子，画一个柱状图出来
%Plot_TwoAliClusterTraceExampleDAG


graph1(1,1:10) = [1,1,0,0,0,0,0,0,0,0];
graph1(2,1:10) = [-1 8 0 0 0 0 0 0 1 0];
graph1(3,1:10) = [0 0 11 0 0 0 0 0 1 0];
graph1(4,1:10) = [0 0 0 1 1 0 0 0 0 0];
graph1(5,1:10) = [0 0 0 -1 2 0 0 1 0 0];
graph1(6,1:10) = [0 0 0 0 0 1 1 0 0 0];
graph1(7,1:10) = [0 0 0 0 0 -1 2 1 0 0];
graph1(8,1:10) = [0 0 0 0 -1 0 -1 22 1 0];
graph1(9,1:10) = [0 -1 -1 0 0 0 0 -1 34 1];
graph1(10,1:10) = [0 0 0 0 0 0 0 0 -1 51];

 graph2(1,1:17) = [1 1 0 1 0 1 0 1 1 1 0 0 0 0 0 0 0];
 graph2(2,1:17) = [-1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0];
 graph2(3,1:17) = [0 -1 1 0 0 0 0 0 0 0 0 1 0 0 0 0 0];
 graph2(4,1:17) = [-1 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0];
 graph2(5,1:17) = [0 0 0 -1 1 0 0 0 0 0 0 1 0 0 0 0 0];
 graph2(6,1:17) = [-1 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0];
 graph2(7,1:17) = [0 0 0 0 0 -1 1 0 0 0 0 1 0 0 0 0 0];
 graph2(8,1:17) = [-1 0 0 0 0 0 0 1 0 0 0 1 0 0 0 0 0];
 graph2(9,1:17) = [-1 0 0 0 0 0 0 0 1 0 0 1 0 0 0 0 0];
graph2(10,1:17) = [-1 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0];
graph2(11,1:17) = [0 0 0 0 0 0 0 0 0 -1 1 1 0 0 0 0 0];
graph2(12,1:17) = [0 0 -1 0 -1 0 -1 -1 -1 0 -1 1 0 1 0 0 0];
graph2(13,1:17) = [0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 0 0];
graph2(14,1:17) = [0 0 0 0 0 0 0 0 0 0 0 -1 -1 1 0 1 0];
graph2(15,1:17) = [0 0 0 0 0 0 0 0 0 0 0 0 -1 0 1 1 0];
graph2(16,1:17) = [0 0 0 0 0 0 0 0 0 0 0 0 0 -1 -1 1 1];
graph2(17,1:17) = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -1 1];

for i=1:length(graph1)
    if graph1(i,i) < 1
        graph1(i,i) = 1;
    end
    if graph1(i,i) > 1
        graph1(i,i) = 1;
    end
end
for i=1:length(graph2)
    if graph2(i,i) < 1
        graph2(i,i) = 1;
    end
    if graph2(i,i) > 1
        graph2(i,i) = 1;
    end
end

%------------例子1-------------------------
Tasknum = length(graph1);
Servernum = 3;
userNum = 1;

[ServerMemory,TaskMemory,Possionrate,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server,EdgeWeight,TaskSize] = GenerateData_NetworkConnect(round(Servernum*(Servernum-1)/4),userNum,Servernum,Tasknum);
%由于只要一个用户
Taskgraph = zeros(Tasknum,Tasknum,userNum);
Taskgraph(:,:,1) = graph1;
Taskgraph = FulFillTaskgraph(Taskgraph,EdgeWeight,TaskSize,userNum,Tasknum);

 [~,~,preFinishTime_p3_1] = P3_network(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
 [~,~,preFinishTime_iwqos_1] = P1_iwqos_network(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
 [~,~,preFinishTime_infocom_1] = P1_infocom_network(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);

 [~,~,preFinishTime_best_1] = P1_IterateNum_network(10000,Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
 
 
 
 %------------例子2-------------------------
% Tasknum = length(graph2);
% Servernum = 3;
% userNum = 1;
% 
% [ServerMemory,TaskMemory,Possionrate,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server,EdgeWeight,TaskSize] = GenerateData_NetworkConnect(round(Servernum*(Servernum-1)/4),userNum,Servernum,Tasknum);
% %由于只要一个用户
% Taskgraph = zeros(Tasknum,Tasknum,userNum);
% Taskgraph(:,:,1) = graph2;
% Taskgraph = FulFillTaskgraph(Taskgraph,EdgeWeight,TaskSize,userNum,Tasknum);
% 
% 
% [~,~,preFinishTime_p3_2] = P3_network(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
%  [~,~,preFinishTime_iwqos_2] = P1_iwqos_network(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
%  [~,~,preFinishTime_infocom_2] = P1_infocom_network(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
% 
%  [~,~,preFinishTime_best_2] = P1_IterateNum_network(500,Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Transferrate_network,Computespeed_Local,ComputeSpeed_server);
 

 


