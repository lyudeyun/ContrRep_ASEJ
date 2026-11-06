import os
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
# calibration
filePath = ''
calibStep = ''
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
			elif arg == 'filePath':
				filePath = argu[0]
			elif arg == 'calibStep':
				calibStep = argu[0]
			elif arg == 'coreNum':
				coreNum = argu[0]
			else:
				continue
			if linenum == 0:
				status = 0
# script name 
for phi_i in range(len(phi_str)):
		property = phi_str[phi_i].split(';')
		filename = model + '_spec_' + str(phi_i + 1) +  '_testCaseNum_' + testCaseNum + '_calibstep_' + calibStep +  '_Calib'
		print(filename)
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

			# parallel computing
			bm.write('coreNum = ' + coreNum + ';\n')
			bm.write('myFLRepair = ContrRep(bm, bmType, mdl, mdlCopy, D_run, is_nor, testSuite, testCaseNum, net, nn_stru, T, Ts, [], in_name, in_range, in_span, icc_name, ic_const, ics_name, oc_name, oc_span, phi_str);\n')
			
			bm.write('folderPath = \'' + filePath + '\';\n')
			bm.write('calibStep = ' + calibStep + ';\n')
			bm.write('[calibBestIndLog, calibFullPopLog] = myFLRepair.calibCheapIncr(folderPath, deParams, coreNum, exConstParams, exNormParams, calibStep);\n')
			bm.write('delete(fullfile([\'breach/Ext/ModelsData/\', \'*_breach.slx\']));\n')
			bm.write('delete(fullfile([\'*.slx\']));\n')
			bm.write('delete(fullfile([\'*.slx.autosave\']));\n')
			bm.write('delete(fullfile([\'*.slx.r202*\']));\n')
			bm.write('delete(fullfile([\'*_breach.slxc\']));\n')
			bm.write('rmdir(\'slprj\', \'s\');\n')
			bm.write('quit force\n')
			bm.write('EOF\n')

		# the generated script is launched directly
		os.chmod('scripts/' + filename, 0o755)
