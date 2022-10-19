%server的计算速度变化。重点是用户本地CPU速度 与 server的计算速度 之间的比值。这里选择改变服务器速度而不是本地速度
%PlotDifferentServerSpeed
%server的计算速度太慢，那还不如全部在本地执行，因为在server执行还会引入通信延迟
%论文没使用这个脚本画出的图

Tasknum = 10;
Servernum = 2;
userNum = 2;

[ServerMemory,TaskMemory,Possionrate,Transferrate,Computespeed_Local,ComputeSpeed_server,EdgeWeight,TaskSize] = GenerateData(userNum,Servernum,Tasknum);
TaskMemory = normrnd(50 ,1,[1 Tasknum]);
ServerMemory =  normrnd(50*Tasknum*0.5/Servernum +25 ,1,[1 Servernum]);
%GenerateData中Computespeed_Local范围是(3,5) ，均值4

 Graph = GenarateGraphParalle(Tasknum,4); %并行度4
 [Taskgraph,Graph] = GenarateGraphCommon(Graph,Tasknum,userNum,0.3); %相似任务占比0.3
 Taskgraph = FulFillTaskgraph(Taskgraph,EdgeWeight,TaskSize,userNum,Tasknum);
 
 ComputationSpeedRatio = [0.25,0.5, 1, 2, 4, 10, 15, 20, 25];
 [~,length] = size(ComputationSpeedRatio);
 for k = 1:length
     %low = 3 * Tasknum * cacheRation/Servernum * ComputationSpeedRatio
    ComputeSpeed_server = normrnd(4 * Tasknum*0.5/2 *ComputationSpeedRatio(k) ,1,[1 Servernum]);
    
    [preCache,preTaskComputationSpeed,preFinishTime] = P1_RankOnNum(Tasknum,userNum,Servernum,ServerMemory,TaskMemory,Possionrate,Taskgraph,Transferrate,Computespeed_Local,ComputeSpeed_server);
    
    k
    y(k) = preFinishTime;
     
 end
 
 plot(ComputationSpeedRatio,y)

 