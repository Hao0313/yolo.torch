function main_Yolo_augment()

clear ; close all; clc
baseUrl = 'http://128.6.5.14:3300/data/tags/';
pptlist = importdata('newlist.data','\n');
pptlist_test = importdata('newlist_test.data','\n');


% imgWidth = 512;
% imgHeight = 549;
resizeW = 448;
resizeH = 448;
celNum = 1;
savePrefix = '0721_1x1';

trDataPath = strcat('results/img_' , savePrefix);
trLabelPath = strcat('results/label_' , savePrefix);
teDataPath = strcat('results/testimg_' , savePrefix);
teLabelPath = strcat('results/testlabel_' , savePrefix);


genData(pptlist,trDataPath,trLabelPath);
fprintf('%s','finish gen training data... \n');
genData(pptlist_test,teDataPath,teLabelPath);
fprintf('%s','finish gen testing data... \n');


function genData(pptlist, dataPath,labelPath)
    for i=1:size(pptlist,1)
        imageName = pptlist(i);
        fprintf('data:start crop image: %s \n',strcat(baseUrl,'ppt_',char(imageName)));
        
        str = urlread(strcat(baseUrl,'ppt_',char(imageName)));
        
        data = JSON.parse(str);
        try
            fprintf('%d,%d \n',size(data.resources,1),size(data.resources,2));
        catch
            fprintf('error \n')
        end
        
        resources = data.resources;
        for j=1:size(resources,2)
            ceil = cell2mat(resources(j));
            url = ceil.url;
            publicId = ceil.public_id;
            %     fprintf('===url:%s\n',url);
            tags = ceil.tags;
            loc = '';
            for k = 1:size(tags,2)
                if strncmpi(tags(k),'stroke_loc_',11),
                    strokeArea = char(tags(k));
                    strokeArea = strokeArea(12:end);
                    loc = strsplit(strokeArea,'%2C');
                end
            end
            try
                img = imread(url);
            catch
                print('error reading url:'+url);
                continue;
            end
            
            [imgH,imgW,channel]=size(img);
            
            if  ~isempty(loc)
                xmin = round(str2num(char(loc(1))));
                ymin = round(str2num(char(loc(2))));
                width = str2num(char(loc(3)));
                height = str2num(char(loc(4)));
            else
                xmin = 0;
                ymin = 0;
                width = 0;
                height = 0;
            end
            
            [resultImg,resultLabel] = calcYolo(img,loc,xmin,ymin,width,height);
            if exist('imagesList','var')
        
                imagesList = [imagesList;resultImg];
                imagesLabel = [imagesLabel;resultLabel];
            else

                imagesList = resultImg;
                imagesLabel = resultLabel;
                %reshape(imagesWeightList,1,imgW*imgH);
            end
            
            %flip for data augmentation
%             imglr = fliplr(img);
%             xminlr = imgW-xmin-width;
%             [resultImg,resultLabel] = calcYolo(imglr,loc,xminlr,ymin,width,height);
%             
%             imagesList = [imagesList;resultImg];
%             imagesLabel = [imagesLabel;resultLabel];
            
            
        end
        
        


    end

    
    save(strcat(dataPath,'.mat'),'imagesList');
    save(strcat(labelPath,'.mat'),'imagesLabel');
    
    
end

function[resultImg,resultLabel] =  calcYolo(img,loc,xmin,ymin,width,height)

    %         Save images into folders
%             imwrite(img,strcat(trDataPath,'/',publicId,'.jpg'));

    %         Save annotation information into folders.
            if  ~isempty(loc)
                [imgH,imgW,channel]=size(img);
                xmax = round(xmin + width-1);
                ymax = round(ymin + height-1);
                x = (xmin+xmax)/2;
                y = (ymin+ymax)/2;
                %fprintf('img rul:%s \n',url);
                %fprintf('x:%d, y:%d, w:%d, h:%d \n',x,y,width,height);
                

                relativeX = x/imgW;
                relativeY = y/imgH;
                relativeW = width/imgW;
                relativeH = height/imgH;

%                 orig_file = fopen(strcat(trLabelPath,'/orig_',publicId,'.txt'),'w');
%                 fprintf(orig_file,'1 %1.5f %1.5f %1.5f %1.5f',xmin,ymin,xmax,ymax);
%                 fclose(orig_file);
% 
%                 file = fopen(strcat(trLabelPath,'/',publicId,'.txt'),'w');
%                 fprintf(file,'1 %1.5f %1.5f %1.5f %1.5f',relativeX,relativeY,relativeW,relativeH);
%                 fclose(file);
                target = zeros(1,celNum,celNum,6);
                target(:,:,:,5) = 1;
                
                cellX = floor(relativeX * celNum);
                cellY = floor(relativeY * celNum);
                cellRelativeX = (relativeX * celNum) - cellX;
                cellRelativeY = (relativeY * celNum) - cellY;
                %fprintf('after: cellX:%d, cellY:%d, x:%d, y:%d, w:%d, h:%d \n',cellX+1,cellY+1,cellRelativeX,cellRelativeY, sqrt(relativeW),  sqrt(relativeH) )
                target(1,cellY+1,cellX+1,:)= [cellRelativeX, cellRelativeY, sqrt(relativeW), sqrt(relativeH), 0 ,1];
                
                resultLabel = target;
            
            else
                emptyLabel = zeros(1,celNum,celNum,6);
                emptyLabel(1,:,:,5) = 1;
                
                resultLabel = emptyLabel;
                
                
                
                
            end
            
            
            
            % transfer image to gray scale and resize image to 480*480.
            grayImg = rgb2gray(imresize(img,[resizeH,resizeW]))';
            
            resultImg = reshape(grayImg,1,resizeH*resizeW);
            


end
end