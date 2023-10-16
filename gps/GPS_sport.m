lat_task=31.02350;
lon_task=121.43150;
num_j=1;                                                             %节点数量
%m=mobiledev;                                                        %建立连接
toward=[0;1];                                                        %小车朝向，N:[0 1]  S:[0 -1]  E:[1 0]  W:[-1 0]
D=[2 1;
   1 -2];                                                            %坐标变换矩阵
XY_task=[lon_task lat_task];
[lat, lon, speed, course, alt, horizacc] = poslog(m);                %获取瞬时坐标
XY=D*[lon(end) lat(end)];
u1=udp('192.168.43.157','RemotePort',25001);                         %端口设置
j=zeros(1,2);
j(1)=31.02330;
j(2)=121.43140;                                                      %节点坐标
jXY=[j;XY_task];
jXY=(D*jXY')';
for i=1:num_j+1
XY_task=jXY(i,:);
while(abs(XY_task(2)-XY(2))>0.00002)                                  %Y方向运动
[lat, lon, speed, course, alt, horizacc] = poslog(m);                %获取瞬时坐标
XY=D*[lon(end);lat(end)];
T=(XY_task(2)>XY(2))*2-1;                                            %获取目标朝向
if (toward(1)*(XY_task(2)-XY(2))>0.00002)
    fwrite(u1,2,'int8');%左转
    pause(2);
elseif (toward(1)*(XY_task(2)-XY(2))<-0.00002)
    fwrite(u1,3,'int8');%右转
    pause(2);
elseif (toward(2)*(XY_task(2)-XY(2))<0.00002)
    fwrite(u1,3,'int8');%后转
    pause(4);
end
toward=[0;T];
fwrite(u1,1,'int8');                                                %直行
end

while(abs(XY_task(1)-XY(1))>0.00002)                                  %X方向运动
[lat, lon, speed, course, alt, horizacc] = poslog(m);                %获取瞬时坐标
XY=D*[lon(end);lat(end)];
T=(XY_task(1)>XY(1))*2-1;                                            %获取目标朝向
if (toward(2)*(XY_task(1)-XY(1))>0.00002)
    fwrite(u1,3,'int8');%右转
    pause(2);
elseif (toward(2)*(XY_task(1)-XY(1))<-0.00002)
    fwrite(u1,2,'int8');%左转
    pause(2);
elseif (toward(1)*(XY_task(1)-XY(1))<0.00002)
    fwrite(u1,3,'int8');%后转
    pause(4);
end
toward=[T;0];
fwrite(u1,1,'int8');                                                %直行
end
end

fclose(u1);%关闭端口
delete(u1);%删除端口
clear u1;%清理缓存