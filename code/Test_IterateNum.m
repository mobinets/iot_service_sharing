%Test_IterateNum
%测试P1算法性能随着迭代次数增多的变化


Tasknum = 20;
Servernum = 2;
userNum = 5;


[ServerMemory,TaskMemory,Possionrate,Transferrate,Computespeed_Local,ComputeSpeed_server,EdgeWeight,TaskSize] = GenerateData(userNum,Servernum,Tasknum);
Graph = GenarateGraphParalle(Tasknum,6); 
[Taskgraph,Graph] = GenarateGraphCommon(Graph,Tasknum,userNum,0.3);
Taskgraph = FulFillTaskgraph(Taskgraph,EdgeWeight,TaskSize,userNum,Tasknum);

%sum = zeros(40,100);
sum = zeros(20,100);

%for Iterationnum=500:500:20000
% for Iterationnum=50:50:1000
for Iterationnum=100:100:2000
%     index = Iterationnum/50;
    index = Iterationnum/100;
    for i = 1:100
        [preCache,~,preFinishTime] = P1_IterateNum(Iterationnum,Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Computespeed_Local,ComputeSpeed_server);
        sum(index,i) = preFinishTime;
    end
    
    index

end


% delay = mean(sum,2);
% Iterationnum=50:50:1000;
% plot(Iterationnum,delay);
