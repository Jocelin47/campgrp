function IceAge_lyapscan_QP_11_6
%%
%% Computes scan of lyapunov exponents QP forcing of various Ice Age models
%% last change 07/6/2017 (AH): added model option 5, TG03
%% last change 28/5/2017 (PA)

rand('twister',199)

% plotfigs=true to plot timeseries
plotfigs=false;
%plotfigs=true;

% model options are
%   1=Palliard Parrenin 2004
%   2=Saltzmann Maasch 1991
%   3=van der Pol as in de Saedleleer et al 2013
%   4=van der Pol - Duffing
%   5=Tziperman-Gildor2003 %% added by AH
%   6=phase oscillator - Mitsui et al 2015
%% uncomment precisely one of the allocations below
% PP04
%p=loadModel(1);
% SM91
p=loadModel(2);
% vdP
%p=loadModel(3);
% vdPD
%p=loadModel(4);
% TG03
%p=loadModel(5);
% PO2
%p=loadModel(6);

% forcing paramters: obliquity
p.omega1=2*pi/41.0;
p.omega2=2*pi/23.0;

% detuning
p.tau=1.0;

p.kt1=1.0;
% scan range for x
xm=0.0;
xp=0.5;

p.kt2=1.0;
% scan range for y
ym=0.0;
yp=0.5;

%resolution for scan
xsteps=4;
ysteps=4;

%integration transient and steps
ttrans=16;
tsteps=512;

xs=(0:xsteps-1)*(xp-xm)/(xsteps-1)+xm;
ys=(0:ysteps-1)*(yp-ym)/(ysteps-1)+ym;

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

axis xy;
xlabel('k_1');
ylabel('k_2');
ttext=sprintf('%s LEs QP KK tsteps=%d ttrans=%d (xs,ys)=(%d,%d)',p.name,tsteps,ttrans,xsteps,ysteps);
title(ttext);
colorbar

ftt=sprintf('%s_QP_KK_ts_%d__tt_%d_xs_%d__ys_%d',p.name,tsteps,ttrans,xsteps,ysteps);

print('-dpdf',ftt);
savefig(ftt);

keyboard;

end

%%
function [lyap]=calc_lyap(tsteps,ttrans,p,plotfigs)


% use timestep that is integer fraction of forcing period
%dt=2*pi*(4*p.omega1);
dt=2*pi/(4*p.omega1);

% arbitrary initial condition
yinit=zeros(2*p.N+1,1);
yinit(1)=0.5;
yinit(p.N+1)=1.0;

t=(1-ttrans)*dt;

%% integration code starts here
tmax=tsteps*dt;

%% run transient first
y0=yinit;
for i=1:ttrans-1
    y1=timestep(y0,p,dt,t);
    y0=y1;
    t=t+dt;
end

% uncomment to record trajectory
yy=zeros(2*p.N+1,tsteps);
tt=zeros(1,tsteps);
% NB t should be zero here
yy(:,1)=y0;
tt(1)=t;

lystart=y0(2*p.N+1);
% now compute LE
for i=1:tsteps-1
    y1=timestep(y0,p,dt,t);
    t=t+dt;
    yy(:,i+1)=y1;
    tt(i+1)=t;
    y0=y1;
    lyend=y0(2*p.N+1);
end
lyap=(lyend-lystart)/tmax;

if plotfigs==true
    figure(1);
    subplot(3,1,1);
    %first compt
    if p.N==3
        plot(tt(:),yy(1,:),'r',tt(:),yy(2,:),'b',tt(:),yy(3,:),'k');
        ylabel('y');
    elseif p.N==2
        plot(tt(:),yy(1,:),'r',tt(:),yy(2,:),'b');
        ylabel('y');
    else 
        plot(tt(:),yy(1,:),'r');
        ylabel('y');
    end
    
    subplot(3,1,2);
    %lyap convergent
    plot(tt(:),yy(2*p.N+1,:));
    ylabel('ll');
    
    %lyap convergent
    subplot(3,1,3);
    plot(tt(20:end),yy(2*p.N+1,20:end)./(tt(20:end)+1));
    ylabel('ftle');
    xlabel('t');
    drawnow();
    keyboard;
end


end

%% figures!

%%
function y = timestep(y0,p,h,t)
% integrate forward one timestep, length h, from t
% ode15s is stiff integrator, ode45 is not

tspan = [t t+h];
%solstep = ode15s(@(t,y) fn_lyaps(y,p,t), tspan, y0);
solstep = ode45(@(t,y) fn_lyaps(t,y,p), tspan, y0);
y=deval(solstep,t+h);

%if p.model==6
%    % for phase oscillator model, round to modulo 2pi
%    temp=y(1);
%    y(1)=temp-2*pi*floor(temp/(2*pi));
%end

end

%%
function [fn] = fn_lyaps(t,y,p)

fn=p.zeros;

% astro forcing same for all models
F=p.kt1*sin(t*p.omega1)+p.kt2*sin(t*p.omega2);

if p.model==1
    % PP04
    % nonlinear vars
    xx=y(1);
    yy=y(2);
    zz=y(3);
    % le direction
    lx=y(4);
    ly=y(5);
    lz=y(6);
    % log le amplitude
    %ll=y(7);
    % x=IV, y=AA, z=mu
    hvs=(1+tanh(-p.KK*(p.h*xx-p.i*yy+p.j)))*0.5;
    dhvs=sech(-p.KK*(p.h*xx-p.i*yy+p.j))^2*0.5;
    % nonlinear eqs
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
    %
    fn(1)=fx;
    fn(2)=fy;
    fn(3)=fz;
    fn(4)=(fxl-lambda*lx);
    fn(5)=(fyl-lambda*ly);
    fn(6)=(fzl-lambda*lz);
    fn(7)=lambda;
    
elseif p.model==2
    % Saltzmann Maasch 1991
    xx=y(1);
    yy=y(2);
    zz=y(3);
    % le direction
    lx=y(4);
    ly=y(5);
    lz=y(6);
    % log le amplitude
    %ll=y(7);
    % SM91 modified
    fx=p.alpha1-p.alpha2*p.c*yy-p.alpha3*xx-p.kth*p.alpha2*zz-p.alpha2*F;
    fy=p.beta1-(p.beta2-p.beta3*yy+p.beta4*yy*yy)*yy-p.beta5*zz+p.Fmu;
    fz=p.gamma1-p.gamma2*xx-p.gamma3*zz;
    % variational ODE from Jacobian
    fxl=lx*(-p.alpha3)+ly*(-p.alpha2*p.c)+lz*(-p.kth*p.alpha2);
    fyl=lx*0+ly*(-p.beta2+2*p.beta3*yy-3*p.beta4*yy*yy)+lz*(-p.beta5);
    fzl=lx*(-p.gamma2)+ly*0+lz*(-p.gamma3);
    % project out expansion direction
    lam=fxl*lx+fyl*ly+fzl*lz;
    lamn=lx*lx+ly*ly+lz*lz;
    % growth rate
    lambda=lam/lamn;
    %
    fn(1)=fx;
    fn(2)=fy;
    fn(3)=fz;
    fn(4)=(fxl-lambda*lx);
    fn(5)=(fyl-lambda*ly);
    fn(6)=(fzl-lambda*lz);
    fn(7)=lambda;
    
elseif p.model==3
    % de Saedeleer, Crucifix, Wieczorek (4a,b)
    xx=y(1);
    yy=y(2);
    % le direction
    lx=y(3);
    ly=y(4);
    % nonlinear ODE
    % extra delta term, xx term in fy changed sign
    fx=-(yy+p.beta-F);
    fy=-p.alpha*(yy*(yy*yy/3-1)-xx);
    % variational ODE
    % from Jacobian
    fxl=-ly;
    fyl=-p.alpha*(-lx+ly*(yy*yy-1));
    % project out zero expansion direction
    lam=fxl*lx+fyl*ly;
    lamn=lx*lx+ly*ly;
    % growth rate
    lambda=lam/lamn;
    %
    fn(1)=fx/p.tt;
    fn(2)=fy/p.tt;
    fn(3)=(fxl-lambda*lx)/p.tt;
    fn(4)=(fyl-lambda*ly)/p.tt;
    fn(5)=lambda/p.tt;
    
elseif p.model==4
    % de Saedeleer, Crucifix, Wieczorek (4a,b) modified to be vdP-Duffing
    xx=y(1);
    yy=y(2);
    % le direction
    lx=y(3);
    ly=y(4);
    % nonlinear ODE
    % extra delta term, xx term in fy changed sign
    fx=-(yy+p.beta-F);
    fy=-p.alpha*(yy*(yy*yy/3-1)-xx*(-1+p.delta*xx*xx));
    % variational ODE
    % from Jacobian
    fxl=-ly;
    fyl=-p.alpha*(-lx*(-1+3*p.delta*xx*xx)+ly*(yy*yy-1));
    % project out zero expansion direction
    lam=fxl*lx+fyl*ly;
    lamn=lx*lx+ly*ly;
    % growth rate
    lambda=lam/lamn;
    % (3,4) gives direction, (5) gives log size
    fn(1)=fx/p.tt;
    fn(2)=fy/p.tt;
    fn(3)=(fxl-lambda*lx)/p.tt;
    fn(4)=(fyl-lambda*ly)/p.tt;
    fn(5)=lambda/p.tt;

elseif p.model==5
    % TG03
    % nonlinear vars
    xx=y(1);
    yy=y(2);
    % le direction
    lx=y(3);
    ly=y(4);
    % log le amplitude
    %ll=y(5);
    % x=V_LI, y=T
    asi=p.Is0*(1+tanh(-p.KK*(p.Tf-yy)))*0.5;
    dasi=p.Is0*sech(-p.KK*(p.Tf-yy))^2*0.5;
    q=p.qr*p.epsq*p.A*exp(-p.B/yy);
    aLI=p.LEW^(1/3)*(xx/(2*sqrt(p.lambda)))^(2/3);
    a=p.aocn+p.alnd;
    % nonlinear eqs
    fx=(p.P0+p.P1*q)*(1-asi/p.aocn)-p.S0+p.SM*F+p.ST*(yy-273.15);
    fy=(p.aocn/p.Cocn)*(-p.eps*p.sigma*yy^4+p.Hs*(1-p.alphaS*asi/a-p.alphaL*aLI/a)*(1-p.alphaC));
    % variational ODE from Jacobian
    fxl=lx*0+ly*(p.P1*p.qr*p.epsq*p.A*p.B*exp(-p.B/yy)/(yy^2)*(1-asi/p.aocn)-(p.P0+p.P1*q)*p.KK*dasi/a+p.ST);
    fyl=lx*(-(p.aocn/p.Cocn)*(1-p.alphaC)*2*p.alphaL*aLI/(3*a*xx))+ly*(-(p.aocn/p.Cocn)*(p.eps*p.sigma*4*yy^3+(1-p.alphaC)*p.alphaS*p.KK*dasi/a));
    % project out expansion direction
    lam=fxl*lx+fyl*ly;
    lamn=lx*lx+ly*ly;
    % growth rate
    lambda=lam/lamn;
    %
    % (3,4) gives direction, (5) gives log size
    fn(1)=fx/p.tt;
    fn(2)=fy/p.tt;
    fn(3)=(fxl-lambda*lx)/p.tt;
    fn(4)=(fyl-lambda*ly)/p.tt;
    fn(5)=lambda/p.tt;

elseif p.model==6
    % Mitsui, Crucifix, Aihara phase oscillator(2015)
    xx=y(1);
    % le direction (trivial but kepts for consistency with above)
    lx=y(2);
    % nonlinear ODE
    temp=p.alpha*(1+p.gamma*F);
    fx=p.beta+temp*(cos(xx)+p.delta*cos(2*xx));
    % variational ODE
    % from Jacobian
    fxl=-lx*temp*(sin(xx)+2*p.delta*sin(2*xx));
    % project out zero expansion direction
    lam=fxl*lx;
    lamn=lx*lx;
    % growth rate
    lambda=lam/lamn;
    % NB second component should be zero
    fn(1)=fx/p.tt;
    fn(2)=(fxl-lambda*lx)/p.tt;
    fn(3)=lambda/p.tt;
    
else
    sprintf('model unknown')
    keyboard
end

%scaling of model time by tau
ts=1/p.tau;

fn=fn*ts;

end

%%

function p=loadModel(mname)

p.model=mname;

if p.model==1
    %internal paramters for PP model
    p.name='PP';
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
    p.N=3;
elseif p.model==2
    %internal paramters for SM model
    p.name='SM';
    p.alpha1=1.673915e1;
    p.alpha2=9.523810e0;
    p.alpha3=1.0e-1;
    p.beta1=5.118377e0;
    p.beta2=6.258680e0;
    p.beta3=2.639456e0;
    p.beta4=3.628118e-1;
    p.beta5=5.833333e-2;
    p.gamma1=1.85125e0;
    p.gamma2=1.125e-2;
    p.gamma3=2.5e-1;
    p.c=4.0e-1;
    p.kth=4.444444e-2;
    p.Fmu=0.0;
    p.N=3;
elseif p.model==3
    % de Saedeleer et al VDP
    p.name='VDP';
    p.alpha=11.11;
    p.beta=0.25;
    % scaling of unforced period
    p.tt=35.09;
    p.N=2;
elseif p.model==4
    % VDVP
    p.name='VDPD';
    p.alpha=2;
    p.beta=0.7;
    p.delta=1.0;
    % scaling of unforced period
    p.tt=13.0;
    p.N=2;
elseif p.model==5
    % TG03
    p.name='TG';
    p.KK=100;        % smoothing heaviside
    p.Tf=270.15;     %T_f (-3degC end value in TG03)
    p.qr=0.7;        %q_r
    p.epsq=0.622;    % epsilon_q
    p.A=2.53E11;     % A [Pa]
    p.B=5.42E3;      % B [K]
    p.LEW=4.E3;      % L^{E-W} [km]
    p.lambda=0.01;    % lambda [km]
    p.P0=1.89216E6;     % P_0 [km^3/kyr]
    p.P1=1.26144E9;      % P_1 [km^3/kyr/Pa]
    p.aocn=20.E6;   % a_{ocn} [km^2]
    p.Is0=0.3*p.aocn;% I_s0 [km^2]
    p.alnd=20.E6;   % a_{lnd} [km^2]
    p.S0=4.7304E6;     % S_0 [km^3/kyr]
    p.SM=2.52288E6;     % S_M [km^3/kyr] strength of forcing    
    p.ST=4.7304E4;   % S_T [km^3/kyr/K]
    p.Cocn=2.935470573313E12;% C_{ocn} [W kyr/K]
    p.eps=0.64;      % epsilon
    p.sigma=5.67E-02;% sigma [W km^-2 K^-4]
    p.Hs=350.E6;       % H_s [W km^-2]
    p.alphaS=0.65;   % alpha_S
    p.alphaL=0.7;    % alpha_L
    p.alphaC=0.27;   % alpha_C
    % scaling of unforced period
    p.tt=13.0;
    p.N=2;
    
elseif p.model==6
    % Mitsui et al 2015 phase oscillator
    p.name='PO2';
    p.alpha=1.0;
    p.beta=1.0006;
    p.gamma=1.0;
    p.delta=0.24;
    % scaling of unforced period
    p.tt=1.0;
    p.N=1;  

else
    sprintf('Model not known')
    keyboard
end

p.zeros=zeros(2*p.N+1,1);

end