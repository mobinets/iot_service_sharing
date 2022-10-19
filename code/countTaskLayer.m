function [layer, TasknumEachLayer] = countTaskLayer(Graph,Tasknum,times,const,userNum)
layer = ones(1, Tasknum);
for i = 1:Tasknum
    if Graph(i, i) == 0
        layer(i) = 0;
    end
end


flag = [1];
for i = 1:Tasknum
    if Graph(i, i) == 0
        continue;
    end
    for j = i+1:Tasknum
        if(Graph(i, j) ~= 0 && ~ismember(j, flag))
            layer(j) = layer(i) + 1;
            % % 把j这一列变0
            flag(end + 1) = j;
            
        end
    end
end
TasknumEachLayer = zeros(1, max(layer));
for i = 1:Tasknum
    if Graph(i, i) == 0
        continue;
    end
    TasknumEachLayer(layer(i)) = TasknumEachLayer(layer(i))+1;
end
path = sprintf("/5b/%d_%d_%d.xls",times, const, userNum)
TasknumEachLayer
xlswrite(path,TasknumEachLayer);