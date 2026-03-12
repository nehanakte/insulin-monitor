clc;
clear;
close all;

%% ================== SIMULATION PARAMETERS ==================

time = (0:1:180)';        % Minutes (COLUMN)

T_init = 3.5;
battery = 100;
peltier_power = 1;

k1 = 0.02;               % Reduced heat leakage
k2 = 0.35;               % Stronger cooling


%% ================== AMBIENT BASE ==================

T_room_base = 28 + 6*sin(0.02*time);


%% ================== INITIALIZATION ==================

N = length(time);

T = zeros(N,1);
B = zeros(N,1);
T_room = zeros(N,1);

T(1) = T_init;
B(1) = battery;
T_room(1) = T_room_base(1);


%% ================== CONTROLLER MEMORY ==================

T_target = 5;

Kp = 1.2;      % Proportional gain (STRONGER)
Ki = 0.05;     % Integral gain

integral_error = 0;


%% ================== SIMULATION ==================

for i = 2:N
    
    pause(1);   % Soft real-time
    
    
    %% ----- Ambient Variation -----
    
    env_noise = 1.2 * randn;
    spike = 0;
    
    if rand < 0.05
        spike = 3 * rand;
    end
    
    T_room(i) = T_room_base(i) + env_noise + spike;
    
    
    %% ----- Battery -----
    
    B(i) = B(i-1) - 0.06 + 0.01*randn;
    
    if B(i) < 0
        B(i) = 0;
    end
    
    
    %% ----- Efficiency -----
    
    efficiency = 0.85 + 0.3*rand;
    
    
    %% ===== PI CONTROLLER =====
    
    error = T(i-1) - T_target;
    
    integral_error = integral_error + error;
    
    cooling = (Kp*error + Ki*integral_error) ...
              * k2 * efficiency * (B(i)/100);
    
    if cooling < 0
        cooling = 0;
    end
    
    
    %% ----- Heat -----
    
    heat = k1 * (T_room(i) - T(i-1));
    
    heat = heat + 0.2*randn;
    
    
    %% ----- Update -----
    
    T(i) = T(i-1) + heat - cooling;
    
    
    %% ----- Safety -----
    
    T(i) = max(min(T(i),8),2);
    
    
    %% ----- Save Live CSV -----
    
    data = [time(1:i) T_room(1:i) T(1:i) B(1:i)];
    
    headers = {'Time','AmbientTemp','ChamberTemp','Battery'};
    
    TBL = array2table(data,'VariableNames',headers);
    
    writetable(TBL,'insulin_data.csv');
    
    
    %% ----- Display -----
    
    fprintf('Time:%3d | Room:%5.1f | Chamber:%4.2f | Battery:%5.1f%%\n',...
        time(i),T_room(i),T(i),B(i));
    
end


%% ================== PLOTS ==================

%% Chamber Temperature
figure;
plot(time,T,'b','LineWidth',2);
xlabel('Time (min)');
ylabel('Temperature (°C)');
title('Insulin Chamber Temperature');
grid on;
saveas(gcf,'chamber_temp.png');


%% Ambient Temperature
figure;
plot(time,T_room,'r','LineWidth',2);
xlabel('Time (min)');
ylabel('Temperature (°C)');
title('Ambient Temperature');
grid on;
saveas(gcf,'ambient_temp.png');


%% Battery
figure;
plot(time,B,'k','LineWidth',2);
xlabel('Time (min)');
ylabel('Battery (%)');
title('Battery Level');
grid on;
saveas(gcf,'battery_level.png');


%% ================== END ==================

disp('----------------------------------');
disp('Simulation Finished');
disp('PI Controller Active');
disp('Target = 5°C');
disp('CSV + Graphs Saved');
disp('----------------------------------');


