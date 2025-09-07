import sys
# path
addpath = []
# benchmark parameters
bench = ''
benchType = ''
model = ''
modelCopy = ''
parameters = []
# dataset for simulation
is_nor = ''
dataset_run = ''
# io parameters
in_name = []
in_range = []
in_span = []
icc_name = []
ic_const = []
ics_name = []
oc_name = []
oc_span = []
# nn parameters
nn = ''
nnStru = ''
# specification
phi_str = []
# test suite
testSuite = ''
testCaseNum = ''
faultType = ''
# fault localisation
flMode = ''
spsMetricList = []
hci = ''
mi = ''
tops = ''
# DE
searchMode = ''
popDimRatio = ''
maxGen = ''
checkpointStep = ''
F = ''
CR = ''
mutSgy = ''
crSgy = ''
pertFactor = ''
initMode = ''
initFolder = ''
popInitMode = ''
# repair parameters
fitnessModeList = []
budget = ''
# parallel computing 
coreNum = ''
# script parameters
status = 0
arg = ''
linenum = 0

with open(sys.argv[1],'r') as conf:
	for line in conf.readlines():
		argu = line.strip().split()
		if status == 0:
			status = 1
			arg = argu[0]
			linenum = int(argu[1])
		elif status == 1:
			linenum = linenum - 1
			if arg == 'addpath':
				addpath.append(argu[0])
			elif arg == 'dataset_run':
				dataset_run = argu[0]
			elif arg == 'is_nor':
				is_nor = argu[0]
			elif arg == 'bench':
				bench = argu[0]
			elif arg == 'benchType':
				benchType = argu[0]	
			elif arg == 'model':
				model = argu[0]
			elif arg == 'modelCopy':
				modelCopy = argu[0]
			elif arg == 'parameters':
				parameters.append(argu[0])
			elif arg == 'in_name':
				in_name.append(argu[0])
			elif arg == 'in_range':
				in_range.append([float(argu[0]),float(argu[1])])
			elif arg == 'in_span':
				in_span = '{'
				for idx in range(len(argu)-1):
					in_span = in_span + argu[idx]+','
				in_span = in_span + argu[len(argu)-1] + '}'
			elif arg == 'icc_name':
				icc_name.append(argu[0])
			elif arg == 'ic_const':
				ic_const.append(argu[0])
			elif arg == 'ics_name':
				ics_name.append(argu[0])
			elif arg == 'oc_name':
				oc_name.append(argu[0])
			elif arg == 'oc_span':
				oc_span = '{'
				for idx in range(len(argu)-1):
					oc_span = oc_span + argu[idx] + ','
				oc_span = oc_span + argu[len(argu)-1] + '}'
			elif arg == 'nn':
				nn = argu[0]
			elif arg == 'nnStru':
				nnStru = argu[0]
			elif arg == 'phi_str':
				complete_phi = argu[0] + ';' + argu[1]
				for a in argu[2:]:
					complete_phi = complete_phi + ' ' + a
				phi_str.append(complete_phi)
			elif arg == 'testSuite':
				testSuite = argu[0]
			elif arg == 'testCaseNum':
				testCaseNum = argu[0]
			elif arg == 'faultType':
				faultType = argu[0]
			elif arg == 'flMode':
				flMode = argu[0]
			elif arg == 'spsMetricList':
				spsMetricList.append(argu[0])
			elif arg == 'hci':
				hci = argu[0]
			elif arg == 'mi':
				mi = argu[0]
			elif arg == 'tops':
				tops = argu[0]
			elif arg == 'popDimRatio':
				popDimRatio = argu[0]
			elif arg == 'maxGen':
				maxGen = argu[0]
			elif arg == 'checkpointStep':
				checkpointStep = argu[0]
			elif arg == 'F':
				F = argu[0]
			elif arg == 'CR':
				CR = argu[0]
			elif arg == 'mutSgy':
				mutSgy = argu[0]
			elif arg == 'crSgy':
				crSgy = argu[0]
			elif arg == 'initMode':
				initMode = argu[0]
			elif arg == 'initFolder':
				initFolder = argu[0]
			elif arg == 'popInitMode':
				popInitMode = argu[0]
			elif arg == 'pertFactor':
				pertFactor = argu[0]
			elif arg == 'budget':
				budget = argu[0]
			elif arg == 'searchMode':
				searchMode = argu[0]
			elif arg == 'fitnessMode':
				fitnessModeList.append(argu[0])
			elif arg == 'coreNum':
				coreNum = argu[0]
			else:
				continue
			if linenum == 0:
				status = 0
# script name 
for phi_i in range(len(phi_str)):
		property = phi_str[phi_i].split(';')
		filename = model + '_spec_' + str(phi_i + 1) +  '_testCaseNum_' + testCaseNum + '_searchmode_' + searchMode + '_budget_' + budget + '_Repair'
		print(filename)
		logname = '\'./output/' + filename + '.log\''
		param = '\n'.join(parameters)
		with open('scripts/'+filename,'w') as bm:
			bm.write('#!/bin/sh\n')
			bm.write('matlab -nodesktop -nosplash <<EOF\n')
			bm.write('clear;\n')
			bm.write('close all;\n')
			bm.write('clc;\n')
			bm.write('bdclose(\'all\');\n')
			bm.write('restoredefaultpath;\n')
			bm.write('userpath(\'reset\');\n')
			bm.write('rehash toolboxcache;\n')
			# addpath
			for ap in addpath:
				bm.write('addpath(genpath(\'' + ap + '\'));\n')

			bm.write('dataset_run = \'' + dataset_run + '\';\n')
			bm.write('if strcmp(dataset_run, \'Null.mat\')\n')
			bm.write('\t D_run = \'\';\n')
			bm.write('else\n')
			bm.write('\t D_run = load(dataset_run);\n')
			bm.write('end\n')
			# load test suite
			if testSuite != '':
				bm.write('load(\'' + testSuite + '\');\n')
			bm.write('testCaseNum = ' + testCaseNum + ';\n')
			# model parameters info
			bm.write('bm = \'' + bench + '\';\n')
			bm.write('bmType = \'' + benchType + '\';\n')
			bm.write('mdl = \''+ model + '\';\n')
			bm.write('mdlCopy = \''+ modelCopy + '\';\n')
			bm.write(param + '\n')
			var_names = [line.split('=')[0].strip() for line in parameters if '=' in line]
			struct_line = "exConstParams = packVarsToStruct(" + ", ".join([f"'{v}', {v}" for v in var_names]) + ");"
			bm.write(struct_line + '\n')

			bm.write('is_nor = ' + is_nor + ';\n')
			bm.write('if is_nor == 1\n')
			bm.write('\t x_gain = D_run.ps_x.gain;\n')
			bm.write('\t x_gain = diag(x_gain);\n')
			bm.write('\t x_offset = D_run.ps_x.xoffset;\n')
			bm.write('\t y_gain = D_run.ps_y.gain;\n')
			bm.write('\t y_offset = D_run.ps_y.xoffset;\n')
			bm.write('end\n')

			bm.write("exNormParams = struct();\n")
			bm.write("exNormParams.is_nor = is_nor;\n")
			bm.write("exNormParams.x_gain = x_gain;\n")
			bm.write("exNormParams.x_offset = x_offset;\n")
			bm.write("exNormParams.y_gain = y_gain;\n")
			bm.write("exNormParams.y_offset = y_offset;\n")

			# io parameters
			bm.write('in_name = {\'' + in_name[0] + '\'')
			for inname in in_name[1:]:
				bm.write(',')
				bm.write('\'' + inname + '\'')
			bm.write('};\n')

			bm.write('in_range = {[' + str(in_range[0][0]) + ' ' + str(in_range[0][1]) + ']')
			for ir in in_range[1:]:
				bm.write(',[' + str(ir[0]) + ' ' + str(ir[1]) + ']')
			bm.write('};\n')
			
			bm.write('in_span = ' + in_span + ';\n')

			if icc_name == []:
				bm.write('icc_name = {};\n')
			else:
				bm.write('icc_name = {\'' + icc_name[0] + '\'')
				for iccname in icc_name[1:]:
					bm.write(',')
					bm.write('\'' + iccname + '\'')
				bm.write('};\n')
				
			if ic_const == []:
				bm.write('ic_const = {};\n')
			else:
				bm.write('ic_const = {' + ic_const[0])
				for iccon in ic_const[1:]:
					bm.write(',')
					bm.write('' + iccon)
				bm.write('};\n')

			bm.write('ics_name = {\'' + ics_name[0] + '\'')
			for icsname in ics_name[1:]:
				bm.write(',')
				bm.write('\'' + icsname + '\'')
			bm.write('};\n')

			bm.write('oc_name = {\'' + oc_name[0] + '\'')
			for ocname in oc_name[1:]:
				bm.write(',')
				bm.write('\'' + ocname + '\'')
			bm.write('};\n')

			bm.write('oc_span = ' + oc_span + ';\n')

			# nn parameters
			bm.write('nn = load(\'' + nn + '\');\n')
			bm.write('net = nn.net;\n')
			bm.write('nn_stru = ' + nnStru + ';\n')

			# specification
			bm.write('phi_str = \'' + property[1] + '\';\n')
			
			bm.write('faultType = \'' + faultType + '\';\n')

			# SpectAcle
			bm.write('flMode = \'' + flMode + '\';\n')
			bm.write('spsMetricList = {\'' + spsMetricList[0] + '\'')
			for metric in spsMetricList[1:]:
				bm.write(',')
				bm.write('\'' + metric + '\'')
			bm.write('};\n')
			bm.write('metNum = numel(spsMetricList);\n')
			bm.write('tops = ' + tops + ';\n')

			# DE
			bm.write('deParams.popDimRatio = ' + popDimRatio + ';\n')
			bm.write('deParams.popSize = deParams.popDimRatio * tops;\n')
			bm.write('deParams.maxGen = ' + maxGen + ';\n')
			bm.write('deParams.checkpointStep = ' + checkpointStep + ';\n')
			bm.write('deParams.F = ' + F + ';\n')
			bm.write('deParams.CR = ' + CR + ';\n')
			bm.write('deParams.mutSgy = ' + mutSgy + ';\n')
			bm.write('deParams.crSgy = ' + crSgy + ';\n')
			bm.write('deParams.pertFactor = ' + pertFactor + ';\n')
			bm.write('deParams.initMode = \'' + initMode + '\';\n')
			bm.write('deParams.initFolder = \'' + initFolder + '\';\n')
			bm.write('deParams.popInitMode = \'' + popInitMode + '\';\n')

			# repair parameters
			bm.write('budget = ' + budget + ';\n')
			bm.write('searchMode = \'' + searchMode + '\';\n')
			bm.write('fitnessModeList = {\'' + fitnessModeList[0] + '\'')
			for fitmode in fitnessModeList[1:]:
				bm.write(',')
				bm.write('\'' + fitmode + '\'')
			bm.write('};\n')
			
			# parallel computing
			bm.write('coreNum = ' + coreNum + ';\n')
			bm.write('rng(round(rem(now, 1)*1000000));\n')

			bm.write('myFLRepair = AutoPatch(bm, bmType, mdl, mdlCopy, D_run, is_nor, testSuite, testCaseNum, net, nn_stru, T, Ts, [], in_name, in_range, in_span, icc_name, ic_const, ics_name, oc_name, oc_span, phi_str);\n')
			
			# convert current CPS to a mutant
			bm.write('mutant = struct();\n')
			bm.write('mutant.TS = testSuite;\n')
			bm.write('mutant.mut_TS = testSuite;\n')
			bm.write('mutant.phi = myFLRepair.phi;\n')
			bm.write('mutant.bug_lb = myFLRepair.minW;\n')
			bm.write('mutant.bug_ub = myFLRepair.maxW;\n')
			bm.write('mutant.bug_mdl = myFLRepair.mdl_m;\n')

			bm.write('simlog.cur_state_set = zeros(testCaseNum, 1);\n')
			bm.write('simlog.cur_diagInfo_suite = cell(1, testCaseNum);\n')
			bm.write('for tci = 1:testCaseNum\n')
			bm.write('\t sysInputs = mutant.TS.testCases(tci).sysInputs;\n')
			bm.write('\t diagInfo = myFLRepair.forwardImpactAnalysis(mutant.bug_mdl, sysInputs, tci);\n')
			bm.write('\t simlog.cur_diagInfo_suite{1, tci} = diagInfo;\n')
			bm.write('\t simlog.cur_state_set(tci, 1) = diagInfo.state;\n')
			bm.write('end\n')
			bm.write('simlog.delta_state = nnz(ones(testCaseNum,1) ~= simlog.cur_state_set);\n')
			bm.write('simlog.cur_safety_rate = numel(find(simlog.cur_state_set > 0));\n')

			bm.write('[~, ~, hyCon] = initMutFLInfo(myFLRepair.weight, nn_stru, 1, spsMetricList);\n')
			bm.write('myFLRepair.posNum4TS = countPosFIWeight(simlog.cur_diagInfo_suite);\n')
			bm.write('hyCon = myFLRepair.constructSpectrum(hyCon, simlog.cur_diagInfo_suite);\n')
			bm.write('hyMCon = repmat(hyCon, metNum, 1);\n')
			bm.write('for mi = 1:metNum\n')
			bm.write('\t [hyMCon(mi,:).spsMetric] = deal(spsMetricList{mi});\n')
			bm.write('end\n')
			bm.write('hyMCon = myFLRepair.SBFL(hyMCon, \'random\');\n')
			
			bm.write('hci = ' + hci + ';\n')
			bm.write('mi = ' + mi + ';\n')
			bm.write('spsWeights = hyMCon(mi,hci).spsWeightList(1:tops,:);\n')
			
			bm.write('mutant.sps_weight = spsWeights;\n')

			bm.write('for rmi = 1:numel(fitnessModeList)\n')
			bm.write('\t fitnessMode = fitnessModeList{1, rmi};\n')
			bm.write('\t for bi = 1:budget\n')
			bm.write('\t\t repLog_ID.K = tops;\n')
			bm.write('\t\t repLog_ID.bi = bi;\n')
			
			bm.write('\t\t resNamePrefix = [mdlCopy, \'_bug_\', num2str(mutant.bug_lb), \'_\', num2str(mutant.bug_ub), \'_K_\', num2str(tops), \'_tssize_\', num2str(testCaseNum), \'_searchmode_\', searchMode, \'_fitmode_\', fitnessMode, \'_budget_\', num2str(bi)];\n')
			bm.write('\t\t deParams.resNamePrefix = resNamePrefix;\n')
			bm.write('\t\t tic;\n')
			bm.write('\t\t if strcmp(searchMode, \'DE\')\n')
			bm.write('\t\t\t [bestIndLog, fullPopLog] = myFLRepair.altWeightSearch(faultType, mutant, \'N/A\', \'N/A\', flMode, spsWeights, fitnessMode, deParams, repLog_ID, coreNum, exConstParams, exNormParams);\n')
			bm.write('\t\t elseif strcmp(searchMode, \'random\')\n')
			bm.write('\t\t\t [bestIndLog, fullPopLog] = myFLRepair.randomRepair(faultType, mutant, \'N/A\', \'N/A\', flMode, spsWeights, deParams, repLog_ID, coreNum, exConstParams, exNormParams);\n')
			bm.write('\t\t else\n')
			bm.write('\t\t\t error(\'Check the searchMode!\');\n')
			bm.write('\t\t end\n')
			bm.write('\t\t delete(fullfile([\'breach/Ext/ModelsData/\', \'*_breach.slx\']));\n')
			bm.write('\t\t delete(fullfile([\'*.slx\']));\n')
			bm.write('\t\t delete(fullfile([\'*.slx.autosave\']));\n')
			bm.write('\t\t delete(fullfile([\'*.slx.r202*\']));\n')
			bm.write('\t\t delete(fullfile([\'*_breach.slxc\']));\n')
			bm.write('\t\t rmdir(\'slprj\', \'s\');\n')
			bm.write('\t end\n')
			bm.write('end\n')
	
			bm.write('logname = ' + logname + ';\n')
			bm.write('sendEmail(logname);\n')
			bm.write('quit force\n')
			bm.write('EOF\n')