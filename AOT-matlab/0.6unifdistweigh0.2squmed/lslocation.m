function [estimX,estimY,BSbanned]=lslocation( BSbroadinfo )
% [estimX,estimY，BSbanned]=lslocation( BSbroadinfo )
%  BSbroadinfo=[ BSid , postionX,positionY,heading,radial]

BSid=1;posX=2;posY=3;heading=4;radial=5;

% 将数据信息本地化

angle=BSbroadinfo(:,heading)+BSbroadinfo(:,radial);
Xposition=BSbroadinfo(:,posX);Yposition=BSbroadinfo(:,posY);

rowNum=size(BSbroadinfo,1); len=1;
BSbanned=zeros(1,rowNum+1);pointsX=zeros(1,rowNum+1); pointsY=zeros(1,rowNum+1); pointsEorr=zeros(1,rowNum+1);
pointsX(len)=0;pointsY(len)=0;pointsEorr(len)=0;BSbanned(len)=0;

% 1、 判断是直线关系确定交点（平行但是与水平方向不垂直 与水平方向垂直但是共线 平行且与水平方向垂直但是不共线 仅仅相交（有垂直线与无垂直线两种） ）
for i=1:1:rowNum-1  
    for j=(i+1):1:rowNum
        % 这里要计算直线的交点，需要做一些判断
        % 1、判断是否平行或者是否为x=c的直线 flag为非负数，平行的权值为1，垂直为2
        flag=0;
        if abs(mod(angle(i,1),180))==abs(mod(angle(j,1),180))
            flag=flag+1;
        end
        if (abs(mod(angle(i,1)+90,360))==90) || (abs(mod(angle(i,1)+90,360))==270)||(abs(mod(angle(j,1)+90,360))==90) || (abs(mod(angle(j,1)+90,360))==270)
            flag=flag+2;
        end
        % 2、依据flag求解直线方程
        switch flag
            case 1
                %如果为同一条线，不用禁止该BS，进行下一步
                ki=tan(angle(i,1)*pi/180+pi/2);kj=tan(angle(j,1)*pi/180+pi/2);
                x0i=Xposition(i,1);y0i=Yposition(i,1);
                x0j=Xposition(j,1);y0j=Yposition(j,1);
                if abs((y0i-x0i*ki)-(y0j-x0j*kj))>=10^(-2)
                    BSbanned(len)=BSbanned(len)+1;BSbanned(BSbanned(len)+1)=BSbroadinfo(i,BSid);
                end
            case 2
                  %确定垂直的那条线，求解出交点
                    x0i=Xposition(i,1);y0i=Yposition(i,1);
                    x0j=Xposition(j,1);y0j=Yposition(j,1);
                    if (abs(mod(angle(i,1)+90,360))==90) || (abs(mod(angle(i,1)+90,360))==270)
                        pointsX(len)=1+pointsX(len);pointsY(len)=1+pointsY(len);pointsEorr(len)=1+pointsEorr(len);
                        
                        pointsX(pointsX(len)+1)=x0i;
                        pointsY(pointsY(len)+1)=y0j+tan(angle(j,1)*pi/180+pi/2)*(x0i-x0j);
                        
                        % 计算交点与距离交点较近的BS之间的距离 得到估计方差
                        pointsEorr( pointsEorr(len)+1 )=(pi/24)^2*0.25*(sqrt( (x0i-pointsX(pointsX(len)+1)).^2+ (y0i-pointsY(pointsY(len)+1)).^2 )+sqrt((x0j-pointsX(pointsX(len)+1)).^2+ (y0j-pointsY(pointsY(len)+1)).^2 )).^2/2;
                    else
                        pointsX(len)=1+pointsX(len);pointsY(len)=1+pointsY(len);pointsEorr(len)=1+pointsEorr(len);
                        
                        pointsX(pointsX(len)+1)=x0j;
                        pointsY(pointsY(len)+1)=y0i+tan(angle(i,1)*pi/180+pi/2)*(x0j-x0i);
                        
                        % 计算交点与距离交点较近的BS之间的距离 得到估计方差
                        pointsEorr( pointsEorr(len)+1 )= (pi/24)^2*0.25*(sqrt( (x0i-pointsX(pointsX(len)+1)).^2+ (y0i-pointsY(pointsY(len)+1)).^2 )+sqrt((x0j-pointsX(pointsX(len)+1)).^2+ (y0j-pointsY(pointsY(len)+1)).^2 )).^2/2;
                    end
            case 3
                %如果不共线则禁止这第i个BS
                x0i=Xposition(i,1);x0j=Xposition(j,1);
                if abs(x0i-x0j)>=10^(-2)
                    BSbanned(len)=BSbanned(len)+1;BSbanned(BSbanned(len)+1)=BSbroadinfo(i,BSid);
                end
            case 0
           %求解线性方程组
                    ki=tan(angle(i,1)*pi/180+pi/2);kj=tan(angle(j,1)*pi/180+pi/2);
                    x0i=Xposition(i,1);x0j=Xposition(j,1);
                    y0i=Yposition(i,1);y0j=Yposition(j,1);

                    pointsX(len)=1+pointsX(len);pointsY(len)=1+pointsY(len);pointsEorr(len)=1+pointsEorr(len);

                    tmp=inv([1,-ki;1,-kj])*[-x0i*ki+y0i,-x0j*kj+y0j]';
                    pointsX(pointsX(len)+1)=tmp(2,1);pointsY(pointsY(len)+1)=tmp(1,1);
                    
                    % 计算交点与距离交点较近的BS之间的距离 得到估计方差
                    pointsEorr( pointsEorr(len)+1 )= (pi/24)^2*0.25*(sqrt( (x0i-pointsX(pointsX(len)+1)).^2+ (y0i-pointsY(pointsY(len)+1)).^2 )+sqrt((x0j-pointsX(pointsX(len)+1)).^2+ (y0j-pointsY(pointsY(len)+1)).^2 )).^2/2;
                    
            otherwise
        end
    end
end

% 用LS求出估计的坐标值
if pointsX(len)==0
    flase=1
else
    pointsEorr((len+1):pointsEorr(len)+1)=1./pointsEorr(len+1:pointsEorr(len)+1);
    
    estimX=sum(pointsX((len+1):(pointsX(len)+1)).*pointsEorr( (len+1):(pointsEorr(len)+1) ) )/sum( pointsEorr( (len+1):pointsEorr( len)+1));
    estimY=sum(pointsY((len+1):(pointsY(len)+1)).*pointsEorr( (len+1):(pointsEorr(len)+1) ) )/sum( pointsEorr( (len+1):pointsEorr( len)+1));
end


