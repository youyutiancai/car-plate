
croppedImages = matchFiles('../projectDetecter/SSIG-SegPlate/training/',223);
function T = matchFiles(directory, a)
% [directory '/*.txt']
    list = dir([directory '*/*.txt']);% reading all the images one by one .
%     list
    ImageFileName=cell(length(list),1);
    Position=cell(length(list),1);

    for i = 1:length(list)
        name=list(i).name;
        folder= list(i).folder;
        fid = fopen([folder '/' list(i).name],'r');
        tline = fgetl(fid);
        tline = fgetl(fid);
        formatSpec = 'position_plate: %i %i %i %i';
        A = sscanf(tline,formatSpec);
        A = A.'; 
        x=A(1); y=A(2); dx=A(3); dy=A(4);
        name(end-2:end) = 'png';
%         name(end-2:end) = 'jpg';
        img_name=[folder '/' name];
        img=imread(img_name);
        low_x=max(x+dx-a,1);
        high_x=min(x,size(img,2)-a);
        low_y=max(y+dy-a,1);
        high_y=min(y,size(img,1)-a);
        box_x=randi([low_x high_x],1,1);
        box_y=randi([low_y high_y],1,1);
%         imshow(img)
%         hold on;
%         rectangle('Position',A,'EdgeColor','r');
        new_img=img(box_y:box_y+a, box_x:box_x+a, :);
        new_img_name=[folder '/cropped_' name];
        imwrite(new_img,new_img_name);
        ImageFileName(i)={new_img_name};
        A=[x-box_x,y-box_y,dx,dy];
%         imshow(new_img)
%         hold on;
%         rectangle('Position',A,'EdgeColor','r');
%         hold off;
        Position(i)={A};
        fclose(fid);
    end
    T = table(ImageFileName,Position);
end
