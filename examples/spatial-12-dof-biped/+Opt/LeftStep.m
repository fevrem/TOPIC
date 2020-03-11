function [cons, vars, cost] = LeftStep(rbm, ncp)

arguments
    rbm (1,1) DynamicalSystem
    ncp (1,1) double
end

    
import casadi.*

% list of constraints enforced at every collocation point

%{
    define the dynamics equations (2nd-order ode + holonomic 
    constraint) that will be enforced implicitly
%}

% opt.settings.ncp = ncp;
% opt.settings.tol = 1E-4;


% equations of motion

NB = rbm.Model.nd;

cons = [];

vars = {};


%q, dq, ddq at every CP
%{
    Notation: vars{i,j} refers to the variables at CP j in Phase i
%}
for i = 1:ncp
    
    vars{1,i}.q = Var('q', NB);
    vars{1,i}.q.Seed = zeros(NB,1);
    vars{1,i}.q.LowerBound = [0;0;0;-pi/2;-pi/2;-pi/2;-2*pi*ones(6,1)];
    vars{1,i}.q.UpperBound = [1;1;1;pi/2;pi/2;pi/2;2*pi*ones(6,1)];
    
    vars{1,i}.dq = Var('dq', NB);
    vars{1,i}.dq.Seed = zeros(NB,1);
    vars{1,i}.dq.LowerBound = -20*ones(NB,1);
    vars{1,i}.dq.UpperBound = 20*ones(NB,1);
    
    vars{1,i}.ddq = Var('ddq', NB);
    vars{1,i}.ddq.Seed = zeros(NB,1);
    vars{1,i}.ddq.LowerBound = -100*ones(NB,1);
    vars{1,i}.ddq.UpperBound = 100*ones(NB,1);
    
    vars{1,i}.u = Var('u', 6);
    vars{1,i}.u.Seed = zeros(6,1);
    vars{1,i}.u.LowerBound = -100*ones(6,1);
    vars{1,i}.u.UpperBound = 100*ones(6,1);

    vars{1,i}.Fc = Var('Fc', 3);
    vars{1,i}.Fc.Seed = zeros(3,1);
    vars{1,i}.Fc.LowerBound = -1000*ones(6,1);
    vars{1,i}.Fc.UpperBound = 1000*ones(6,1);    
    
    vars{1,i}.tau = Var('tau', 1);
    vars{1,i}.tau.Seed = linspace(0,1,ncp);
    vars{1,i}.tau.LowerBound = -0.5;
    vars{1,i}.tau.UpperBound = 0.5;    
    
end


% phase variable defined at first CP
vars{1,1}.theta = Var('theta', 1);
vars{1,1}.theta.Seed = 0;
vars{1,1}.theta.LowerBound = -2;
vars{1,1}.theta.UpperBound = 2;    

% phase variable defined at last CP
vars{1,ncp}.theta = Var('theta', 1);
vars{1,ncp}.theta.Seed = 0;
vars{1,ncp}.theta.LowerBound = -2;
vars{1,ncp}.theta.UpperBound = 2;   

% final time
vars{1,ncp}.tf = Var('tf', 1);
vars{1,ncp}.tf.Seed = 0.5;
vars{1,ncp}.tf.LowerBound = 0.1;
vars{1,ncp}.tf.UpperBound = 1.5;  




% phase variable at beggining of step
cons = Constraint.addConstraint(cons);
cons{end}.Name = 'tau(0) = 0';

vars{1,1}.theta.sym - rbm.Model.c*vars{1,1}.q.sym


mlfrffr
cons{end}.SymbolicExpression = theta.sym(1) - rbm.Model.c*rbm.States.q.sym;
[cons{end}.DependentVariables, cons{end}.DependentVariablesID] = assignVars({theta, rbm.States.q});
cons{end}.Function = Function('f', cons{end}.DependentVariables, {cons{end}.SymbolicExpression});
cons{end}.Occurrence = 1;



    



lffrfr



%%


% options are 'point', 'line', or 'plane' contact
cons = Opt.RightStance(cons, rbm, ncp);


% could say one instance of it
tf = Var('tf', 1);
tf.LowerBound = 0.1;
tf.UpperBound = 1.5;
tf.Seed = 0.5;
vars.tf = tf;




% Right Leg End Starts at 0
cons = Constraint.addConstraint(cons);
cons{end}.Name = 'Stance @0';
cons{end}.SymbolicExpression = rbm.BodyPositions{12,2};
[cons{end}.DependentVariables, cons{end}.DependentVariablesID] = assignVars({rbm.States.q});
cons{end}.Function = Function('f', cons{end}.DependentVariables, {cons{end}.SymbolicExpression});
cons{end}.Occurrence = 1;



% Left Leg End Ends on the Ground
cons = Constraint.addConstraint(cons);
cons{end}.Name = 'Stance @T';
cons{end}.SymbolicExpression = rbm.BodyPositions{12,2}(3);
[cons{end}.DependentVariables, cons{end}.DependentVariablesID] = assignVars({rbm.States.q});
cons{end}.Function = Function('f', cons{end}.DependentVariables, {cons{end}.SymbolicExpression});
cons{end}.Occurrence = 1;




if 0
    % phase variable at beginning and end (could be time or could be mechanical phase variable)
    %theta = Var('theta')
    theta = Var('theta', 2);
    %theta.sym = SX.sym(theta.ID, 2);
    %theta.ID = 'theta';
    theta.LowerBound = [-10; -10];
    theta.UpperBound = [10; 10];
    theta.Seed = zeros(2,1);
    vars.theta = theta;


    % phase variable at beggining of step
    cons = Constraint.addConstraint(cons);
    cons{end}.Name = 'tau(0) = 0';
    cons{end}.SymbolicExpression = theta.sym(1) - rbm.Model.c*rbm.States.q.sym;
    [cons{end}.DependentVariables, cons{end}.DependentVariablesID] = assignVars({theta, rbm.States.q});
    cons{end}.Function = Function('f', cons{end}.DependentVariables, {cons{end}.SymbolicExpression});
    cons{end}.Occurrence = 1;



    % phase variable at end of step
    cons = Constraint.addConstraint(cons);
    cons{end}.Name = 'tau(end) = 1';
    cons{end}.SymbolicExpression = theta.sym(2) - rbm.Model.c*rbm.States.q.sym;
    [cons{end}.DependentVariables, cons{end}.DependentVariablesID] = assignVars({theta, rbm.States.q});
    cons{end}.Function = Function('f', cons{end}.DependentVariables, {cons{end}.SymbolicExpression});
    cons{end}.Occurrence = ncp;



    % normalized phase variable
    tau = Var('tau', 1);
    tau.LowerBound = -1;
    tau.UpperBound = 2;
    tau.Seed = linspace(0, 1, ncp);
    vars.tau = tau;


    % normalized phase variable throughout step
    cons = Constraint.addConstraint(cons);
    cons{end}.Name = 'tau_i = Normalized Phase Variable';
    cons{end}.SymbolicExpression = tau.sym - (rbm.Model.c*rbm.States.q.sym - theta.sym(1))/(theta.sym(2) - theta.sym(1));
    [cons{end}.DependentVariables, cons{end}.DependentVariablesID] = assignVars({tau, theta, rbm.States.q});
    cons{end}.Function = Function('f', cons{end}.DependentVariables, {cons{end}.SymbolicExpression});


    % monotonic phase variable
    cons = Constraint.addConstraint(cons);
    cons{end}.Name = 'Monotonic Phase Variable';
    cons{end}.SymbolicExpression = rbm.Model.c*rbm.States.dq.sym;
    [cons{end}.DependentVariables, cons{end}.DependentVariablesID] = assignVars({rbm.States.dq});
    cons{end}.Function = Function('f', cons{end}.DependentVariables, {cons{end}.SymbolicExpression});
    cons{end}.UpperBound = Inf;
    cons{end}.LowerBound = 0;



end




%% Enforce state constraints during stance


rbm.States.q.LowerBound = [0;0;0;-pi/2;-pi/2;-pi/2;-2*pi*ones(6,1)];
rbm.States.q.UpperBound = [1;1;1;pi/2;pi/2;pi/2;2*pi*ones(6,1)];
rbm.States.q.Seed = 0*ones(NB,ncp);

rbm.States.dq.LowerBound = -20*ones(NB,1);
rbm.States.dq.UpperBound = 20*ones(NB,1);
rbm.States.dq.Seed = 0*ones(NB,ncp);

rbm.States.ddq.LowerBound = -100*ones(NB,1);
rbm.States.ddq.UpperBound = 100*ones(NB,1);
rbm.States.ddq.Seed = 0*ones(NB,ncp);

rbm.Inputs.u.LowerBound = -100*ones(6,1);
rbm.Inputs.u.UpperBound = 100*ones(6,1);
rbm.Inputs.u.Seed = 0*ones(6,ncp);



cost.RunningCost = str2func('Opt.ObjectiveFun')

cost.FinalCost = str2func('Opt.FinalCost')



return





% 2 options: open-loop or virtual-constraints


return


lffrrff


% phase variable at t = 0
t_plus = SX.sym('phase_var_0');

% phase variable at t = T
t_minus = SX.sym('phase_var_T');

% normalized phase variable
s_var = SX.sym('norm_phase_var');





derPhaseVarCon







rjffr



switch rbm.dynamics

    case 'hybrid'

        [q_minus, qd_minus] = Model.get_x_minus( rbm );
        obj.Functions.q_minus  = Function('f', { q } , { q_minus } );     
        obj.Functions.qd_minus = Function('f', { q , qd } , { qd_minus } );  
        
end






switch obj.Problem.desired_trajectory.option

    case 'virtual-constraint'

        fprintf('\n\t- desired trajectories: virtual constraints')
        
        % phase variable at t = 0
        t_plus = SX.sym('phase_var_0');

        % phase variable at t = T
        t_minus = SX.sym('phase_var_T');

        % normalized phase variable
        s_var = SX.sym('norm_phase_var');

        switch obj.Problem.desired_trajectory.type
            
            case 'bezier'

                % number of actuated DOF
                number_actuated_DOF = size(rbm.model.B,2); 

                % order of bezier polynomial
                bezier_order = obj.Problem.desired_trajectory.order;
                
                % define the matrix of Bezier coefficients
                alpha = Control.bezier_coefficients( bezier_order , number_actuated_DOF );

                % compute symbolic forms of desired trajectories and derivatives
                [ phi , dphi_dtheta , d2phi_dtheta2 ] = Control.bezier_trajectory( alpha , s_var , t_minus , t_plus );

        
            otherwise
                error('Only Bezier polynomials are supported for now.')
                
        end
        
        
        parameterization_type = obj.Problem.desired_trajectory.param;
        
        
        
        % controller outputs and time derivatives
        [Y,DY,DDY] = Control.controller_output( rbm , q , qd , qdd , phi , dphi_dtheta , d2phi_dtheta2 , parameterization_type );

        obj.Functions.Control.y   = Function('f',{ q , alpha , s_var , t_plus , t_minus } , { Y } );
        obj.Functions.Control.dy  = Function('f',{ q , qd , alpha , s_var , t_plus , t_minus } , { DY } );
        obj.Functions.Control.ddy = Function('f',{ q , qd , qdd , alpha , s_var , t_plus , t_minus } , { DDY } );

        
        
    case 'free'
        
        %error('need to add this')
        fprintf('\n\t- desired trajectories: free')

    otherwise
        error('Options for desired_trajectory are ''free'', ''virtual-constraint''.')

end


fprintf('\n')
dline(1,'-')
fprintf('\n')



% must be list of constraints
Dynamics




end
