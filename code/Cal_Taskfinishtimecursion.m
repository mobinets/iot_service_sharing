function [rs] = Cal_Taskfinishtimecursion(Tasknum_cur,Tasknum,index)
%Cal_Taskfinishtime函数会调用该函数
%递归计算第index个任务的实际完成时间你，类似于函数Rankrecursion
MAX = 0;
for j=1:Tasknum
    if(index == j)
        continue;
    end
    if(Tasknum_cur(j,j) == 0)
        continue;
    end
    if(Tasknum_cur(index,j) == 0)
        continue;
    end
    
    if(Tasknum_cur(index,j) < 0) %任务j是任务i的前驱任务
        temp = Cal_Taskfinishtimecursion(Tasknum_cur,Tasknum,j) + Tasknum_cur(j,index); %Tasknum_cur(j,index)才是正数
        if(MAX < temp)
            MAX = temp;
        end
    end
end

rs = Tasknum_cur(index,index) + MAX;
    
end

