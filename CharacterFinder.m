% Based on the paper "Font and Background Color Independent Text Binarization" by
% T Kasar, J Kumar and A G Ramakrishnan
% http://www.m.cs.osakafu-u.ac.jp/cbdar2007/proceedings/papers/O1-1.pdf
%% read image
pout = imread('../plate_img_sample/4698.png');
figure
subplot(2,3,1)
imshow(pout);
title('Original Figure');

%% obtain and pre-process the grayscale image
if size(pout,1) * size(pout,2) > 30000
    img_gray = rgb2gray(pout);
    
else
     pout = imresize(pout,3);
    pout = rgb2gray(pout);
    pout_imadjust = imadjust(pout);
    pout_histeq = histeq(pout);
    pout_adapthisteq = adapthisteq(pout);
    img_gray = pout_adapthisteq;
end

img_gray = medfilt2(img_gray);

subplot(2,3,2);
imshow(img_gray);
title("Gray Scale");

%% find the edges
[m, n, ~] = size(img_gray);

E = edge(img_gray,'canny');
subplot(2,3,3);
imshow(E);
title("Edge Graph");

%% group the objects with connected pixels and box the qualifiedobjects
[mask, num] = bwlabel(E, 8);
region = regionprops(mask, 'BoundingBox', 'Area');
bx = vertcat(region.BoundingBox);
area = vertcat(region.Area);
ratio = bx(:, 3) ./ bx(:, 4);

%aspect ratio
valid = bx(find((area>15)&...
            (ratio<1 & ratio > 0.1 )&(area<...
             m*n/5)),:);
subplot(2,3,4);
% figure();
imshow(img_gray);
 for i = 1:size(valid, 1)
     rectangle('Position', [valid(i, 1), valid(i, 2), valid(i, 3), valid(i, 4)], ...
         'EdgeColor', 'r', 'LineWidth', 2)
 end
title("Box Before filter");
% all the valid bounding box
accept_idx = [];

%% further filter out the characters 
% and find the objects that are most likely to be characters

% all the bounding box vertexs
X = valid(:, 1);
Y = valid(:, 2);
W = valid(:, 3);
H = valid(:, 4);
reject_idx = [];

for i = 1:size(valid, 1)
    current_bbx = valid(i, :);
    EB_in = EBINT(valid, current_bbx);
    if (isempty(EB_in) ~= 1)
        EB_in
        if (length(EB_in) < 3)
            reject_idx = [reject_idx; EB_in];
        else
            reject_idx = [reject_idx; i];
        end
    end
    

end
subplot(2,3,5);
valid(reject_idx, :) = [];
% figure();
imshow(img_gray);
for i = 1:size(valid, 1)
    rectangle('Position', [valid(i, 1), valid(i, 2), valid(i, 3), valid(i, 4)], ...
        'EdgeColor', 'g', 'LineWidth', 2)
end
title("Box after filter");
box_area = valid(:,3).*valid(:,4);
array = [];
count = [];
result = {};
for i = 1:size(valid,1)
    flag= 0;
    % group by similar height 
    for idx = 1:size(array,1)
        if (array(idx,4) >= valid(i,4) - 3 && array(idx,4) <= valid(i,4)+3)
            flag = 1;
            result{idx} = [result{idx}; valid(i,:)];
            break;
        end        
    end
    %if no group, create one 
    if (flag == 0)
        array = [array;valid(i,1) valid(i,2) valid(i,3) valid(i,4)]; 
        result{size(array,1)} = [valid(i,1) valid(i,2) valid(i,3) valid(i,4)];
    end
end
for i = 1:size(array, 1)
    rectangle('Position', [array(i, 1), array(i, 2), array(i, 3), array(i, 4)], ...
        'EdgeColor', 'b', 'LineWidth', 2)
end

new_result = {};
for i = 1:size(array,1)
    count_arr = [];
    count_result = [];
    result_arr = [];
    cur_group = result{i};
    %for each group with similar height
    for j = 1 : size(cur_group,1)
        flag = 0;
        % check if can be classify to previous group with similar y value
        for k = 1:size(count_arr,1)
            if (count_arr(k,3) >= 0.7 * cur_group(j,3) && 1.3* count_arr(k,3) <= cur_group(j,3))
                count_result(k) = count_result(k) + 1;
                flag = 1;
                break;
            end
               
        end
        %if no similar y value, create one 
        if (flag == 0)
             count_arr = [count_arr; cur_group(j,1) cur_group(j,2) cur_group(j,3) cur_group(j,4)];
             count_result(size(count_arr,1)) = 0;
        end
         
    end
    %find the max vote for y value 
    max_val = -1;
    max_idx = 1;
    for l = 1:size(count_result, 2)
        if (count_result(l) > max_val)
            max_val = count_result(l);
            max_idx = l;
        end
    end
    % only take the max voted y value to result cell
    for j = 1:size(cur_group,1)
        if (cur_group(j,3) >= 0.7 * cur_group(max_idx,3) && cur_group(j,3) <= 1.3* cur_group(max_idx,3))
            result_arr = [result_arr; cur_group(j,:)];
        end
    end
   
    new_result{i} = result_arr;
    
end
possible_char = {}
k = 1;
% max have at least 3 character 
for i = 1 : size(new_result,2)
    temp_arr = new_result{i};
    if size(temp_arr,1) > 3
        possible_char{k} = new_result{i};
        k = k + 1;
    end
end
average_area = zeros(1,size(possible_char,1));
for i = 1 : size(possible_char,2)
    current = possible_char{i};
    average_area(i) = mean(current(:,3).*current(:,4));
end
[max_area,i]=max(average_area);
target = possible_char{i};


valid = round(target);
offset  =1;
 BW_EB = ones(size(img_gray));
for i = 1:size(valid, 1)
    i;
   % find the overlap between box region and label region
    box_region = img_gray(valid(i, 2):valid(i, 2) + valid(i, 4) -1, valid(i, 1):(valid(i, 1) + valid(i, 3) - 1));
    label_region = E(valid(i, 2):valid(i, 2) + valid(i, 4) -1, valid(i, 1):(valid(i, 1) + valid(i, 3) - 1));
    F_EB = box_region(label_region == 1);
    F_EB = mean(F_EB);

   B = [];
  
   % I(x-1, y-1) I(x-1, y) I(x, y-1)
   if (valid(i,2)-1 > 1 && valid(i,1) -1 > 1)
      B = [B img_gray(valid(i,2)-1, valid(i,1) -1)];
      B = [B img_gray(valid(i,2)-1, valid(i,1))];
      B = [B img_gray(valid(i,2), valid(i,1) -1)];
   end

   %I(x+w+1,y−1),I(x+w,y−1),I(x+w+1,y),
   if (valid(i,2) + valid(i,4) +1< m)&& (valid(i,1) - 1 > 1)
      B = [B img_gray(valid(i,2) + valid(i,4) + 1, valid(i,1) -1)];
      B = [B img_gray(valid(i,2) + valid(i,4)), valid(i,1) -1];
      B = [B img_gray(valid(i,2) + valid(i,4) + 1, valid(i,1))];
   end

   %I(x − 1, y + h + 1), I(x − 1, y + h), I(x, y + h + 1),
   if (valid(i,2) - 1 > 1) && (valid(i,1) + valid(i,3) + 1 < n)
      B = [B img_gray(valid(i,2)-1, valid(i,1) + valid(i,3) + 1)];
      B = [B img_gray(valid(i,2) -1, valid(i,1) + valid(i,3))];
      B = [B img_gray(valid(i,2), valid(i,1) + valid(i,3) +1)];
   end
   %I(x + w + 1, y + h + 1), I(x + w, y + h + 1), I(x + w + 1, y + h)
   if (valid(i,2) + valid(i,4) + 1 < m) && (valid(i,1) + valid(i,3) + 1<n)
      B = [B img_gray(valid(i,2)+valid(i,4) + 1, valid(i,1) + valid(i,3) + 1)];
      B = [B img_gray(valid(i,2)+valid(i,4), valid(i,1)+valid(i,3)+ 1)];
      B = [B img_gray(valid(i,2)+valid(i,4) + 1, valid(i,1)+valid(i,3))];
   end
   B_EB = median(double(B));
   if (F_EB >=B_EB)
      BW_EB(valid(i, 2):valid(i, 2) + valid(i, 4) -1, valid(i, 1):(valid(i, 1) + valid(i, 3) - 1)) = double(box_region) < F_EB;
   else 
      BW_EB(valid(i, 2):valid(i, 2) + valid(i, 4) -1, valid(i, 1):(valid(i, 1) + valid(i, 3) - 1)) = double(box_region) >= F_EB;
   end
end
subplot(2,3,6);
imshow(BW_EB);
title("Final Result");
ocr(BW_EB, 'CharacterSet', 'abcdefghijklmnopqrstuvwxyz0123456789')

