benchmark = 'ACC';
dataset = 'ACC_vl_28_ve_22_ddefault_105_spec_1_Orig_Feb_7.mat';

nor_dataset = ['New_Nor_', dataset];
ps_x_conf = [benchmark,'_ps_x.mat'];
ps_y_conf = [benchmark,'_ps_y.mat'];

if exist(nor_dataset,'file')
    load(nor_dataset);
else
    if exist(dataset,'file')
        load(dataset);

        % if strcmp(benchmark, 'ACC')
        %     for idx = 1:501
        %         tr_ic_cell{1, idx} = tr_ic_cell{1, idx}(3:5,:);
        %     end
        % end

        % dataIn, dataOut
        dataIn =  tr_ic_cell;
        dataOut = tr_oc_cell;
        
        % preprocess train input data and apply ps to test input data
        dataIn_Mat = cell2mat(dataIn);
        % mapminmax
        [~,ps_x] = mapminmax(dataIn_Mat,0,1);
        index_in = find((ps_x.xmax - ps_x.xmin) == 0);
        
        ps_x.gain(index_in) = 1.0 ./ ps_x.xmax(index_in);
        ps_x.xmax(index_in) = 1;
        ps_x.xmin(index_in) = 1;
        
        nor_dataIn = mapminmax('apply',dataIn,ps_x);
        % preprocess train ouput data and apply ps to test output data
        dataOut_Mat = cell2mat(dataOut);
        % mapminmax
        [~,ps_y] = mapminmax(dataOut_Mat,0,1);
        index_out = find((ps_y.xmax - ps_y.xmin) == 0);
        
        ps_y.gain(index_out) = 1.0 ./ ps_y.xmax(index_out);
        
        ps_y.xmax(index_out) = 1;
        ps_y.xmin(index_out) = 1;
        
        nor_dataOut = mapminmax('apply',dataOut,ps_y);
        % coresponding to the code:  dataIn = new_tr_ic; dataOut = new_tr_oc;
         new_tr_ic = nor_dataIn;
         new_tr_oc = nor_dataOut;

         tr_ic_cell = new_tr_ic;
         tr_oc_cell = new_tr_oc;
         
        
        save(nor_dataset, 'tr_rob_set','tr_in_cell','tr_ic_cell','tr_oc_cell','ps_x','ps_y');
    else
        error('benchmark does not exist');
    end
end
