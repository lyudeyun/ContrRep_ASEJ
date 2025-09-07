function [nor_trainIn,nor_trainOut,ps_x,ps_y] = preprocess(dataset)
% pre-process the dataset for better training the neural network
%
% Input:
% benchmark
% Outputs:
% nor_trainIn
% nor_trainOut
% ps_x: the configure of ps_x
% ps_y: the configure of ps_y

% trainIn
% trainOut

trainset = [benchmark,'_trainset.mat'];
nor_trainset = ['nor_',benchmark,'_trainset.mat'];
ps_x_conf = [benchmark,'_ps_x.mat'];
ps_y_conf = [benchmark,'_ps_y.mat'];


if exist(nor_trainset,'file')
    load(nor_trainset);
else
    if exist(trainset,'file')
        load(trainset);
        % preprocess train input data and apply ps to test input data
        trainIn_Mat = cell2mat(trainIn);
        % mapminmax
        [~,ps_x] = mapminmax(trainIn_Mat,0,1);
        index_in = find((ps_x.xmax - ps_x.xmin) == 0);

        ps_x.gain(index_in) = 1.0 ./ ps_x.xmax(index_in);
        ps_x.xmax(index_in) = 1;
        ps_x.xmin(index_in) = 1;

        nor_trainIn = mapminmax('apply',trainIn,ps_x);
        % preprocess train ouput data and apply ps to test output data
        trainOut_Mat = cell2mat(trainOut);
        % mapminmax
        [~,ps_y] = mapminmax(trainOut_Mat,0,1);
        index_out = find((ps_y.xmax - ps_y.xmin) == 0);

        ps_y.gain(index_out) = 1.0 ./ ps_y.xmax(index_out);

        ps_y.xmax(index_out) = 1;
        ps_y.xmin(index_out) = 1;

        nor_trainOut = mapminmax('apply',trainOut,ps_y);

        save(nor_trainset,'nor_trainIn','nor_trainOut','ps_x','ps_y');
    else
        error('benchmark does not exist');
    end
end
end