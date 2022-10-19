function [rs,f] = findRoot(f,i)
%并查集，findRoot()函数

% while f(i) ~= i
%     i = f(i);
% end
% 
% rs = i;

if f(i) ~= i
    [temp,f] = findRoot(f,f(i));
    f(i) = temp;
end

rs = f(i);
end

