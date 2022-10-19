%不同的服务器数量
%Plot_DifferentServerNum
%P1的参数w = 6
%论文没用这个图，这个脚本被Plot_DifferentServerNumToTaskNumRatio代替

%Servernum 1~9
Tasknum = 20;
userNum = 4;
% Servernum_mean = 5;
% Servernum_max = 9;
Servernum_mean = 10;
Servernum_max = 19;


 Graph = GenarateGraphParalle(Tasknum,8);%并行度为8
 [Taskgraph,Graph] = GenarateGraphCommon(Graph,Tasknum,userNum,0.3); %相似任务占比0.3
 

%TaskMemory、Possionrate、Computespeed_Local、EdgeWeight、TaskSize 这几个数据量不变
[ServerMemory,TaskMemory,Possionrate,Transferrate,Computespeed_Local,ComputeSpeed_server,EdgeWeight,TaskSize] = GenerateData(userNum,Servernum_mean,Tasknum);

Taskgraph = FulFillTaskgraph(Taskgraph,EdgeWeight,TaskSize,userNum,Tasknum);

%ServerMemory的长度设置为(1,Servernum_max)，但是其中属性按照Servernum_mean来设置
low = round(20 * Tasknum * 0.6/Servernum_mean + 25);
high =  round(80 * Tasknum * 0.6/Servernum_mean + 25);
ServerMemory = randi([low high],1,Servernum_max);%每个边缘服务器的内存大小

Transferrate = 4 + 2*rand(Servernum_max+userNum,Servernum_max+userNum); %这应该是个对称矩阵
for i=2:(Servernum_max+userNum)
    for j = 1:(i-1)
        Transferrate(i,j) = Transferrate(j,i);
    end
end

low = round(3 * Tasknum * 0.6/Servernum_mean * 20);
high = round(5 * Tasknum * 0.6/Servernum_mean * 20);
ComputeSpeed_server = randi([low high],1,Servernum_max);

% x = 1:1:9;
x = 1:2:19;
index = 1;
for Servernum =1:2:19
    [preCache,preTaskComputationSpeed,preFinishTime] = P1_RankOnNum(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Computespeed_Local,ComputeSpeed_server);
    
    %[preCache_infocom,preTaskComputationSpeed_infocom,preFinishTime_infocom] = P1_infocom(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Computespeed_Local,ComputeSpeed_server);
    [preCache_iwqos,preTaskComputationSpeed_iwqos,preFinishTime_iwqos] = P1_iwqos(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Computespeed_Local,ComputeSpeed_server);
    
    [preCache_infocom2,preTaskComputationSpeed_infocom2,preFinishTime_infocom2] = Copy_of_P1_infocom(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Computespeed_Local,ComputeSpeed_server);
    
    Servernum
    y(index) = preFinishTime;
    %y2(index) = preFinishTime_infocom;
    y3(index) = preFinishTime_iwqos;
    y4(index) = preFinishTime_infocom2;
    index = index + 1;
end

plot(x,y);
hold on;
%plot(x,y2);
plot(x,y4);
plot(x,y3);