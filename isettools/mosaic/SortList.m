function [list] = SortList(list)% [list] = SortList(list)% Sorts the list of receptor positions according to ascending% order on the two columns.% Sort the first column[temp,index] = sort(list(:,1));list(:,1) = list(index,1);list(:,2) = list(index,2);% Sort the second columnstarti = 1;while (starti < length(list))  for i = starti:length(list);    if (list(i,1) ~= list(starti,1))      break;     end  end  sort(list(starti:i-1,2));  starti = i;end            