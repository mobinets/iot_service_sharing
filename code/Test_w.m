%测试P1函数随参数w变化时的性能变化

Tasknum = 20;
Servernum = 2;
userNum = 3;

[ServerMemory,TaskMemory,Possionrate,Transferrate,Computespeed_Local,ComputeSpeed_server,EdgeWeight,TaskSize] = GenerateData(userNum,Servernum,Tasknum);
Graph = GenarateGraphParalle(Tasknum,6); 
[Taskgraph,Graph] = GenarateGraphCommon(Graph,Tasknum,userNum,0.3);
Taskgraph = FulFillTaskgraph(Taskgraph,EdgeWeight,TaskSize,userNum,Tasknum);


sum = zeros(20,100);

index = 1;
for w=0.25:0.25:5
    for i = 1:100
        [~,~,preFinishTime] = P1_w(w,Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Computespeed_Local,ComputeSpeed_server);
        sum(index,i) = preFinishTime;
    end
    
    index = index +1;
    index
end
