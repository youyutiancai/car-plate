% assume the we already have the result table
n = size(result,1);
incorrect = 0;
wrong=0;
notfound=0;
correct=0;
diff=zeros(1,n);
for i=1:n
    detected=result.Detected{i};
    actual=result.Position{i};
    if isempty(detected)
        notfound=notfound+1;
        diff(i)=Inf;
        continue
    end
    detected = [detected(:,1:2), detected(:,1:2)+detected(:,3:4)];
    actual = [actual(:,1:2), actual(:,1:2)+actual(:,3:4)];
    row=detected-actual;
    diff(i)=max(abs(row));
end
fprintf('%.4f\n',length(find(diff>2000))/n);
fprintf('%.4f\n',length(find(diff>100&diff<2000))/n);
fprintf('%.4f\n',length(find(diff>60&diff<=100))/n);
fprintf('%.4f\n',length(find(diff>20&diff<=60))/n);
fprintf('%.4f\n',length(find(diff<=20))/n);