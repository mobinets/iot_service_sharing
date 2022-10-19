function [ServerMemory,TaskMemory,Possionrate,Transferrate,Computespeed_Local,ComputeSpeed_server,EdgeWeight,TaskSize] = GenerateData(userNum,Servernum,Tasknum)
%生成Taskgraph后，随机生成各种数据，包括各点和边的权重、任务（消耗）和服务器内存、服务其间传输速度、各DAG泊松参数、本地和服务器计算速度
%EdgeWeight和TaskSize这两个参数，用于改变Taskgraph中各点和边的权重（现在Taskgraph只表示了拓扑，各任务和边存在则是1/-1），
%   是FulFillTaskGraph函数的输入


cacheRation = 0.5;%把能够被缓存的任务比例控制在cacheRatio附近
TaskMemory = randi([20 80],1,Tasknum);%每种类型任务所需内存大小，[20,80]整数 GB
low = round(20 * Tasknum * cacheRation/Servernum + 25);
high =  round(80 * Tasknum * cacheRation/Servernum + 25);
ServerMemory = randi([low high],1,Servernum);%每个边缘服务器的内存大小




%任务间通信量（边的权重） [2,8]
EdgeWeight = zeros(Tasknum,Tasknum);
for i = 1:(Tasknum-1)
    for j=(i+1):Tasknum
        EdgeWeight(i,j) = randi([8 16]); %改成[4,16]
    end
end
% for k=1:userNum %Taskgraph中各边的权重
%     for i = 1:(Tasknum - 1)
%         for j = (i+1):Tasknum
%             Taskgraph(i,j,k) = Taskgraph(i,j,k) * EdgeWeight(i,j);
%         end
%     end
%     
%     for i = 2:Tasknum
%         for j = 1:(i-1)
%             Taskgraph(i,j,k) = - Taskgraph(j,i,k);
%         end
%     end
% end


%服务器间通信速度 (4,6) 。这样通信时间范围[0.33, 2]，均值为1
%2021/01/15，修改为(1,4)，通信时间范围[0.5,8]，均值2（没改）
Transferrate = 4 + 2*rand(Servernum+userNum,Servernum+userNum); %这应该是个对称矩阵
for i=2:(Servernum+userNum)
    for j = 1:(i-1)
        Transferrate(i,j) = Transferrate(j,i);
    end
end



%每种类型任务的计算量（点的权重） [10,30]  M CPU cycles
TaskSize =  randi([10 30],1,Tasknum);
% for k=1:userNum
%     for i=1:Tasknum
%         if Taskgraph(i,i,k) == 1
%             Taskgraph(i,i,k) = TaskSize(i);
%         end
%     end
% end

%本地计算速度， (3,5)   本地计算时间和 点的权重、本地计算速度、各DAG泊松参数 有关。  注意 μ>λ
%希望本地执行花费时间比通信时间要长几倍，不然全部本地执行最快，没必要卸载
Computespeed_Local = 3 + 2*rand(Tasknum,userNum);  %此时本地计算的μ范围是 (0.1, 0.5)
%λ范围(0.01, 0.05);
Possionrate = 0.01 + 0.04*rand(1,userNum); 


%每个边缘服务器的计算速度  
%2121/01/15，把ComputationSpeedRatio从10提升到20
ComputationSpeedRatio = 20; %在服务器执行的任务，在经过速度分配后，分配到的速度对应的μ是本地执行的多少倍
%Tasknum * cacheRation/Servernum平均每个服务器上有几个任务瓜分速度
low = round(3 * Tasknum * cacheRation/Servernum * ComputationSpeedRatio);
high = round(5 * Tasknum * cacheRation/Servernum * ComputationSpeedRatio);
ComputeSpeed_server = randi([low high],1,Servernum);


end

