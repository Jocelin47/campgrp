function PP_lyapscan_QP_28_5
%%
%% Computes scan of lyapunov exponents for Palliard-Parrenin system
%% last change 28/5/2017 (PA)

rand('twister',199)

% plotfigs=true to plot timeseries
plotfigs=false;
%plotfigs=true;

%internal paramters for model
p.a=1.3;
p.b=0.5;
p.c=0.8;
p.d=0.15;
p.e=0.5;
p.f=0.5;
p.g=0.4;
p.h=0.3;
p.i=0.7;
p.j=0.27;
p.taui=15;
p.taua=12;
p.taumu=5;

% smoothing for heaviside
p.KK=100;

% rescale time
p.tau=1;

% forcing paramters: obliquity only
p.omega1=2*pi/41.0;
p.omega2=2*pi/23.0;

%p.alpha=11.11;
%taup=140.0*35.09/100;
p.tau=1.0;

p.kt1=1.0;
xm=0.0;
xp=1.0;

p.kt2=1.0;
ym=0.0;
yp=2.0;

%resolution for scan
xsteps=250;
ysteps=250;

%integration transient and steps
ttrans=16;
tsteps=256;

xs=(0:xsteps-1)*(xp-xm)/(xsteps-1)+xm;
ys=(0:ysteps-1)*(yp-ym)/(ysteps-1)+ym;
% tulc for beta=
%tulcs=taus*100/35.09;
% most positive lyap exponent
ly=zeros(xsteps,ysteps);

for ii=1:xsteps
    p.kt1=xs(ii);
    for jj=1:ysteps
        p.kt2=ys(jj);
        [lp]=calc_lyap(tsteps,ttrans,p,plotfigs);
        ly(jj,ii)=lp;
    end
    sprintf('%d percent completed',(floor(ii/xsteps*100)))
end

figure(2);
clf;

imagesc(xs,ys,ly,[-0.015,0.015]);
%imagesc(tulcs,gammas,ly,[-0.05,0.05]);
axis xy;
xlabel('kt1');
%xlabel('T_{ULC}');
ylabel('kt2');
ttext=sprintf('PP LEs QP KK tsteps=%d ttrans=%d (xs,ys)=(%d,%d)',tsteps,ttrans,xsteps,ysteps);
title(ttext);
colorbar

ftt=sprintf('PP_QP_KK_ts_%d__tt_%d_xs_%d__ys_%d',tsteps,ttrans,xsteps,ysteps);

%print('-depsc2',ftt);
print('-dpdf',ftt);
savefig(ftt);


keyboard;

return

%%
function [lyap]=calc_lyap(tsteps,ttrans,p,plotfigs)

% use integer fractions of forcing period
dt=2*pi*(4*p.omega1);

yinit=[0.5,0.0,0.0,1.0,0.0,0.0,0.0];
t=(1-ttrans)*dt;

%% integration code starts here
tmax=tsteps*dt;

%% transient first
y0=yinit;
for i=1:ttrans-1
    y1=timestep(y0,p,dt,t);
    y0=y1;
    t=t+dt;
end

% uncomment to record trajectory
yy=zeros(7,tsteps);
yy(:,1)=y0;
% t should be zero here
tt(1)=t;

lystart=y0(7);
for i=1:tsteps-1
    y1=timestep(y0,p,dt,t);
    t=t+dt;
    yy(:,i+1)=y1;
    tt(i+1)=t;
    y0=y1;
    lyend=y0(7);
end

lyap=(lyend-lystart)/tmax;


if plotfigs==true
    figure(1);
    subplot(3,1,1);
    %first compt
    plot(tt(:),yy(1,:),'r',tt(:),yy(2,:),'b',tt(:),yy(3,:),'k');
    
    subplot(3,1,2);
    %lyap convergent
    plot(tt(:),yy(7,:));
    
    %lyap convergent
    subplot(3,1,3);
    plot(tt(20:end),yy(7,20:end)./(tt(20:end)+1));
    drawnow();
%    keyboard;
end


return

%% figures!




%%
function y = timestep(y0,p,h,t)
% integrate forward one timestep, length h, from t
% ode15s is stiff integrator ode45 is not

tspan = [t t+h];
%solstep = ode15s(@(t,y) fn_lyaps(y,p,t), tspan, y0);
solstep = ode45(@(t,y) fn_lyaps(y,p,t), tspan, y0);
y=deval(solstep,t+h);

return

%%
function fn=fn_lyaps(y,p,t)

%global p

fn=[0;0;0;0;0;0;0];

% nonlinear vars
xx=y(1);
yy=y(2);
zz=y(3);
% le direction
lx=y(4);
ly=y(5);
lz=y(6);
% log le amplitude
ll=y(7);

% PP
% forcing
F=p.kt1*sin(t*p.omega1)+p.kt2*sin(t*p.omega2);
%+p.gamma2*sin(t*p.omega2);
% x=IV, y=AA, z=mu
hvs=(1+tanh(-p.KK*(p.h*xx-p.i*yy+p.j)))*0.5;
dhvs=sech(-p.KK*(p.h*xx-p.i*yy+p.j))^2*0.5;

fx=(-p.a*zz-p.b*F+p.c-xx)/p.taui;
fy=(xx-yy)/p.taua;
fz=(p.d*F-p.e*xx+p.f*hvs+p.g-zz)/p.taumu;
% variational ODE from Jacobian
fxl=lx*(-1/p.taui)+ly*0+lz*(-p.a/p.taui);
fyl=lx*(1/p.taua)+ly*(-1/p.taua)+lz*0;
fzl=lx*(-p.e+p.f*dhvs*(-p.KK*p.h))/p.taumu+ly*(p.f*dhvs*(p.KK*p.i))/p.taumu+lz*(-1/p.taumu);

% project out expansion direction
lam=fxl*lx+fyl*ly+fzl*lz;
lamn=lx*lx+ly*ly+lz*lz;
% growth rate
lambda=lam/lamn;

% scale everything internal by tau
ts=1/p.tau;

% (3,4) gives direction, (5) gives log size
fn(1)=fx*ts;
fn(2)=fy*ts;
fn(3)=fz*ts;
fn(4)=(fxl-lambda*lx)*ts;
fn(5)=(fyl-lambda*ly)*ts;
fn(6)=(fzl-lambda*lz)*ts;
fn(7)=lambda*ts;


return

%%