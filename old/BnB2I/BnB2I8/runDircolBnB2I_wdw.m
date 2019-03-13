function [p,utraj,xtraj,z,traj_opt,F,info]=runDircolBnB2I_wdw
% from an initial balancing condition, take one step and return to the
% balance upright.

p = BnBPlant2D2I();
N = [30;30;30]; %Knot points First nd Second Mode

options.u_const_across_transitions = true; %set
options.periodic = false; %Supposing another constraint x(tf)=x(0)

traj_opt = HybridTrajectoryOptimization(@DircolTrajectoryOptimization, p,[1;2;1],N,{[0.2 5],[0.2 5],[0.2 5]},options); %Test 10

x0 = [0; 0; 0; 0; 0;    0; 0; 0; 0; 0];

t1 = 1;
x1 = [1; 1; 1.2; -0.5; 0;      0; 2; 1.5; 1; 0];

t2 = 2.4;
x2 = [3; 0; 0; 0; 0.3;     1; 0; 0; 0; 0];

tf = 5;
xf = [4; 0; 0; 0; 0;    0; 0; 0; 0; 0];

t_init{1} = linspace(0,t1,N(1));
t_init{2} = linspace(0,t2-t1,N(2));
t_init{3} = linspace(0,tf-t2,N(3));

traj_init{1}.x0 = x0;
traj_init{2}.x0 = x1;
traj_init{3}.x0 = x2;

traj_opt = traj_opt.addModeStateConstraint(1,ConstantConstraint(x0),1);
%traj_opt = traj_opt.addModeStateConstraint(2,ConstantConstraint(xf),N(2));
traj_opt = traj_opt.addModeStateConstraint(3,ConstantConstraint(xf),N(3));
%traj_opt = traj_opt.addModeStateConstraint(2,BoundingBoxConstraint([4;-0.5;-inf(8,1)],[4.1;0.5;inf(8,1)]),N(3));

%traj_opt = traj_opt.addModeStateConstraint(1,BoundingBoxConstraint([0;-inf(3,1)],[0;inf(3,1)]),1);%Unneeeded but crushing, maybe by initial randonmess
%traj_opt = traj_opt.addModeStateConstraint(1,BoundingBoxConstraint([.1;-inf(3,1)],inf(4,1)),N(1));% "Inclined?" but unneeded

% traj_opt = traj_opt.addModeStateConstraint(2,BoundingBoxConstraint([1;-inf(9,1)],[1;inf(9,1)]),1);
% traj_opt = traj_opt.addModeStateConstraint(2,BoundingBoxConstraint([.1;-inf(3,1)],inf(4,1)),N(1));% "Inclined?" but unneeded

for i=1:3
for k=1:traj_opt.N(i)
    cons_fun = @(x,u) windw1(x,u);
    cons_con = FunctionHandleConstraint(-Inf,0,12, cons_fun);
    cons_xind{1} = traj_opt.mode_opt{i}.x_inds(:,k) + traj_opt.var_offset(i); % xm
    cons_xind{2} = traj_opt.mode_opt{i}.u_inds(:,k) + traj_opt.var_offset(i); % u
    traj_opt = traj_opt.addConstraint(cons_con,cons_xind);
end
end
for i=1:3
for k=1:traj_opt.N(i)
    cons_fun = @(x,u) windw2(x,u);
    cons_con = FunctionHandleConstraint(-Inf,0,12, cons_fun);

    cons_xind{1} = traj_opt.mode_opt{i}.x_inds(:,k) + traj_opt.var_offset(i); % xm
    cons_xind{2} = traj_opt.mode_opt{i}.u_inds(:,k) + traj_opt.var_offset(i); % u
    traj_opt = traj_opt.addConstraint(cons_con,cons_xind);
end
end


% 
traj_opt = traj_opt.addModeRunningCost(1,@cost);
traj_opt = traj_opt.addModeRunningCost(2,@cost);
traj_opt = traj_opt.addModeRunningCost(3,@cost);

% traj_opt = traj_opt.addModeFinalCost(1,@finalcost);% Well-set
% traj_opt = traj_opt.addModeFinalCost(3,@finalcost);% Well-set

traj_opt = traj_opt.compile();
%traj_opt = traj_opt.setCheckGrad(true);
% snprint('snopt.out');
tic
[xtraj,utraj,z,F,info] = solveTraj(traj_opt,t_init,traj_init);
toc
% if (nargout<1)
%   v = CompassGaitVisualizer(p);
%   figure(1); clf;
%   fnplt(utraj);
%   
%   figure(2); clf; hold on;
%   fnplt(xtraj,[2 4]);
%   fnplt(xtraj,[3 5]);
%   
%   playback(v,xtraj);
%   
% end
end

function [g,dg] = cost(t,x,u);
R = 0.1*eye(2);
g = sum((R*u).*u,1);
dg = [zeros(1,1+size(x,1)),2*u'*R];
end

function [h,dh] = finalcost(t,x)
h=t;
dh = [1,zeros(1,size(x,1))];
end
% 
% function J = postImpactTrajCost(T,X,U,p)
% % encourage post-impact trajectory to leave collision surface orthogonally
% t0=T(1); x0=X(:,1); u0=U(:,1);
% xdot0=p.modes{2}.dynamics(t0,x0,u0);
% dphidx = [1,1,0,0]; % gradient of foot collision guard 1 w/respect to x
% J=100*abs(dphidx*xdot0)./norm(dphidx)./norm(xdot0);
% end
% 
