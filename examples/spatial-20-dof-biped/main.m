%% LOAD DYNAMICAL SYSTEM

clear; clc;

tic
[rbm] = ld_model(...
    {'model',@Model.spatial_20_dof_biped},...
    {'debug',false});
toc


%% SPECIFY CONTACT 

% Right leg end in stance
rbm.Contacts{1} = Contact(rbm, 'Point',...
    {'Friction', true},...
    {'FrictionCoefficient', 0.6},...
    {'FrictionType', 'Pyramid'},...
    {'ContactFrame', rbm.BodyPositions{12,2}});


%% CREATE NLP

%{
- nfe: 
    number of finite elements
- LinearSolver:
    options: 'ma57', 'ma27', 'mumps'
- CollocationScheme:
    options: 'HermiteSimpson', 'Trapezoidal'
%}
nlp = NLP(rbm,...
    {'NFE', 25},...
    {'CollocationScheme', 'HermiteSimpson'},...
    {'LinearSolver', 'mumps'},...
    {'ConstraintTolerance', 1E-4});

% Create functions for dynamics equations 
nlp = ConfigFunctions(nlp, rbm);


%% VIRTUAL CONSTRAINTS

nlp = AddVirtualConstraints(nlp, rbm,...
    {'PolyType', 'Bezier'},...
    {'PolyOrder', 5},...
    {'PolyPhase', 'time-based'});


%% LOAD USER-DEFINED CONSTRAINTS

[nlp, rbm] = LoadConstraints(nlp, rbm);


%% LOAD SEED

%[nlp, rbm] = LoadSeed(nlp, rbm);
[nlp, rbm] = LoadSeed(nlp, rbm,...
    'spatial-20-dof-biped-seed.mat');
 

%% TRANSCRIPTION

tic
nlp = ParseNLP(nlp, rbm);
toc


%% SOLVE NLP

nlp = SolveNLP(nlp);


%% EXTRACT SOLUTION

data = ExtractData(nlp, rbm);


%% SAVE SEED

seed.q = data.pos;
seed.qd = data.vel;
seed.qdd = data.acc;
seed.t = data.t;
seed.Fc_1 = data.Fc1;
seed.a = data.a;
seed.u = data.input;

% can be used as seed
str2save = 'spatial-20-dof-biped-seed.mat';
if false
    save(str2save, 'seed')
end

%% ANIMATE SOLUTION

% optimized a left step (right leg in stance)
qLeftStep = data.pos;

% append data to qAnim to animate several steps
qAnim = qLeftStep;
tAnim = data.t;

% Flip states
R = Model.RelabelingMatrix();

% compute symmetric right step 
qRightStep = R*data.pos;
qRightStep(1,:) = qRightStep(1,:) + range(qLeftStep(1,:));
qRightStep(2,:) = qRightStep(2,:) + data.pbody{9,1}(2,end) + data.pbody{12,1}(2,end);

% append
qAnim = [qAnim, qRightStep];
tAnim = [tAnim, data.t + tAnim(end)];

% total number of strides (2x steps)
N_strides = 3;
for i = 1:N_strides-1

    % left step
    qLeftStep = data.pos;
    qLeftStep(1,:) = qLeftStep(1,:) + range(qAnim(1,:));
    qAnim = [qAnim, qLeftStep]; %#ok<*AGROW>
    tAnim = [tAnim, data.t + tAnim(end)];

    % right step
    qRightStep = R*data.pos;
    qRightStep(1,:) = qRightStep(1,:) + range(qAnim(1,:));
    qRightStep(2,:) = qRightStep(2,:) + data.pbody{9,1}(2,end) + data.pbody{12,1}(2,end);
    qAnim = [qAnim, qRightStep];
    tAnim = [tAnim, data.t + tAnim(end)];

end

% options: true or false 
anim_options.bool = true;

anim_options.axis.x = [-0.1 0.6];
anim_options.axis.y = [-0.1 0.4];
anim_options.axis.z = [0 1.5];

% skips frame to animate faster 
anim_options.skip_frame = 1;

% views to show. Options: {'3D','frontal','sagittal','top'}
anim_options.views = {'3D'};%','frontal','sagittal','top'};


% save options
anim_options.save_movie    = false;
anim_options.movie_name    = 'spatial_20_dof_biped.mp4';
anim_options.movie_quality = 100; % scalar between [0 100], default 75
anim_options.movie_fps     = 30;  % frame rate, default 30

% create a light object or not
anim_options.lights = true;

% can pass figure as 5th argument
Anim.animate(rbm, tAnim, qAnim, anim_options)
%set(gcf,'menubar','figure')
%set(gcf,'menubar','none')


