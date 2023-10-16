load Test.mat
lat=Position.latitude;
lon=Position.longitude;
spd=Position.speed;
yaw=AngularVelocity.Y;

t=(1:length(lat))';
ta=(1:length(Acceleration.X))';
data = [];
data(:,1) = t;
accdata = [];
accdata(:,1) = ta;
accdata(:,2) = Acceleration.X;
accdata(:,3) = -Acceleration.Y;
accdata(:,4) = Acceleration.Z;

for i = 1:length(data(:,1))
    p_t = data(i,1);
    for j = 1:length(ta)
        a_t = ta(j);
        if abs(a_t - p_t) <0.05
             data(i,4) = accdata(j,2);
             data(i,5) = accdata(j,3);
        end
    end
end

data(:,2) = lon;
data(:,3) = lat;

vx=[];
vy=[];

for i=1:length(spd)
    vy(i,:) = spd(i)*sin(yaw(i));
    vx(i,:) = spd(i)*cos(yaw(i));
end

kfdata(:,1) = data(:,1);
kfdata(:,2) = data(:,4);
kfdata(:,3) = data(:,5);
kfdata(:,4) = data(:,5);   %未使用z方向加速度，随意赋值
kfdata(:,5) = data(:,2);
kfdata(:,6) = data(:,3);
kfdata(:,7) = vx;
kfdata(:,8) = vy;
kfdata(:,9) = zeros(length(data),1);
kfdata(:,10) = zeros(length(data),1);



X_ACC = data(:,4);%X轴加速度 
Y_ACC = data(:,5);%Y轴加速度
earth = 6378137;%地球半径
L = length(X_ACC);

lat_1 = zeros(L,1);
lon_1 = zeros(L,1);
lat = zeros(L,1);
lon = zeros(L,1);
d_x = zeros(L,1);
d_y = zeros(L,1);
d_lon = zeros(L,1);
d_lat = zeros(L,1);

%转为经纬度
for i = 1:L
    lon_1(i) = floor(data(i,2));
    lat_1(i) = floor(data(i,3));
    lon(i) = lon_1(i) + (mod(data(i,2),1)/60)*100;
    lat(i) = lat_1(i) + (mod(data(i,3),1)/60)*100;
end
%%%%%%%%%%%%%%%%%%%
%%计算距离上电距离
for i = 1:L
   d_lon(i) = lon(i)-lon(1); 
   d_lat(i) = lat(i)-lat(1);
   d_x(i) = 2 * 3.14 * earth * (d_lon(i)/360);
   d_y(i) = 2 * 3.14 * (earth / cos(d_lat(i)/360 * 2 * 3.14))*(d_lat(i)/360);
end

pm_x = d_x; %GPS经度差
am_x = X_ACC;%X轴加速度数据
pm_y = d_y;  %GPS纬度差
am_y = Y_ACC;%Y轴加速度数据
t = 0.02; %运行周期
X1kf = zeros(3,1);
X2kf = zeros(3,1);
%状态转移矩阵和协方差矩阵
F = [1,t,0.5*t*t;0,1,t;0,0,1];%状态转移矩阵
P1 = [10,0,0;0,2,0;0,0,0.8]; %定义经度纬度协方差矩阵
P2 = [10,0,0;0,2,0;0,0,0.8];
Q = [10,0,0;0,0.8,0;0,0,0.8];%过程噪声
H = [1,0,0;0,0,1];%观测矩阵
R = [100,0;0,100]; %观测噪声
I = [1,0,0;0,1,0;0,0,1];
XX = zeros(L,1);
YY = zeros(L,1);
%对经纬度分别融合
for i = 1:L
    %预测
    X1_pre = F * X1kf;
    P1_pre = F*P1*F'+Q;
    
    Z1 = [pm_x(i);5];
    e1 = Z1 - H * X1_pre;
    Kg1 = P1_pre * H' * inv(H*P1_pre*H' + R);
    %更新
    X1kf = X1_pre + Kg1*e1;
    P1 = (I - Kg1*H)*P1_pre;
    XX(i) = X1kf(1);
end
%对经纬度分别融合
for i = 1:L
    %预测
    X2_pre = F * X2kf;
    P2_pre = F*P2*F'+Q;
    Z2 = [pm_y(i);5];
    e2 = Z2 - H * X2_pre;
    Kg2 = P2_pre * H' * inv(H*P2_pre*H' + R);
    %更新
    X2kf = X2_pre + Kg2*e2;
    P2 = (I - Kg2*H)*P2_pre;
    YY(i) = X2kf(1);
end
lat=Position.latitude;
lon=Position.longitude;

wm = webmap('World Imagery');
s = geoshape(lat,lon);
wmline(s,'Color','red','Width',2); % 设置轨迹颜色和大小

lat2=(YY-d_y)/3.14/earth*180+lat;
lon2=(XX-d_x)/3.14/earth*180+lon;

wm2 = webmap('World Imagery');
s2 = geoshape(lat2,lon2);
wmline(s2,'Color','blue','Width',2); % 设置轨迹颜色和大小



figure
hold on; box on;
plot(d_x,d_y,'r');
plot(XX,YY,'b');
legend('原始轨迹','EKF轨迹');
