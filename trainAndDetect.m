%first run this to generate the full table,
% For cropped images, run the crop.m file
fullTable = matchFiles('SSIG-SegPlate/training/');

%% train the network
options = trainingOptions('sgdm', ...
'MiniBatchSize', 100, ... % change this for fasterRCNN
'InitialLearnRate', 1e-6, ...
'MaxEpochs', 3);
lg = alexnet; %'resnet50' for ResNet50, '' is important
rcnn = trainRCNNObjectDetector(fullTable, lg, options, 'NegativeOverlapRange', [0 0.3]);
% croppedTable for cropped images
save('rcnn_fullImage.mat', 'rcnn');
%% Run network fusion on the whole testing database.
% We can share the networks if you want
load('rcnn_alexnet_cropped_normal.mat')
rcnn2=rcnn;
load('rcnn_alex_faster_crop.mat')

result=testOn('SSIG-SegPlate/testing',rcnn,rcnn2);
save('result.mat', 'result');
% after get the tables, run the calculateAccuracy.m
%%  same as testOn, but for one image
img = imread('SSIG-SegPlate/validation/Track81/Track81[01].png');
load('rcnn_alex_faster_crop.mat')
[bbox, score, label] = detect(rcnn, img);
[score, idx] = max(score);
bbox = bbox(idx, :);
annotation = sprintf('%s: (Confidence = %f)', label(idx), score);
detectedImg = insertObjectAnnotation(img, 'rectangle', bbox, annotation);
imtool(detectedImg);
y=max(bbox(1)+round(bbox(3)/2)-150,1);
x=max(bbox(2)+round(bbox(4)/2)-150,1);
y=min(y,1620);
x=min(x,780);
w=300;
h=300;

new_img=img(x:(x+w),y:(y+h),:);
imtool(new_img)

img=new_img;
load('rcnn_alexnet_cropped_normal.mat')
[bbox, score, label] = detect(rcnn, img);
[score, idx] = max(score);
bbox = bbox(idx, :);
annotation = sprintf('%s: (Confidence = %f)', label(idx), score);
detectedImg = insertObjectAnnotation(img, 'rectangle', bbox, annotation);
imtool(detectedImg)
%% prepare the table for full-table networks
function T = matchFiles(directory)
% [directory '/*.txt']
    list = dir([directory '*/*.txt']);% reading all the images one by one .

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
        name(end-2:end) = 'png';
        ImageFileName(i)={[folder '/' name]};
        Position(i)={A};
        fclose(fid);
    end
    T = table(ImageFileName,Position);
end
%% test the network fusion method on the whole testing database
function [result] = testOn(directory,rcnn,rcnn2)
% [directory '/*.txt']
    list = dir([directory '/*/*.txt']);% reading all the images one by one .

    ImageFileName=cell(length(list),1);
    Position=cell(length(list),1);
    Detected=cell(length(list),1);
    
    for i = 1:length(list)
        name=list(i).name;
        folder= list(i).folder;
        fid = fopen([folder '/' list(i).name],'r');
        tline = fgetl(fid);
        tline = fgetl(fid);
        formatSpec = 'position_plate: %i %i %i %i';
        A = sscanf(tline,formatSpec);
        A = A.';
        name(end-2:end) = 'png';
        imageFileName=[folder '/' name];
        ImageFileName(i)={imageFileName};
        img = imread(imageFileName);
        [bbox, score, label] = detect(rcnn, img);
        [score, idx] = max(score);
        bbox = bbox(idx, :);
%         annotation = sprintf('%s: (Confidence = %f)', label(idx), score);
%         detectedImg = insertObjectAnnotation(img, 'rectangle', bbox, annotation);
% imtool(detectedImg)
        y=max(bbox(1)+round(bbox(3)/2)-150,1);
        x=max(bbox(2)+round(bbox(4)/2)-150,1);
        y=min(y,1620);
        x=min(x,780);
        w=300;
        h=300;
        new_img=img(x:(x+w),y:(y+h),:);
        [bbox, score, label] = detect(rcnn2, new_img);
        [score, idx] = max(score);
        bbox = bbox(idx, :);
        bbox = [bbox(1)+y,bbox(2)+x,bbox(3),bbox(4)];
        Detected(i)={bbox};
        Position(i)={A};
        fclose(fid);
    end
    result = table(ImageFileName,Position,Detected);
end
