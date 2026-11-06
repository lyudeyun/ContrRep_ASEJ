function caseTable = benchmarkCases()
% BENCHMARKCASES The ten benchmarks of the paper, in the order of its tables.
% Columns: row label, results folder, DE subfolder, Random subfolder, folder
% of the ISAR results (results/contrrep/ of the ISAR repository).
caseTable = {
 'ACC$^{\C_{1}}$',  'ACC1_Phi1', 'tops_10_popSize_20_gen_50', 'tops_10_popSize_20_gen_50', 'ACC1_Phi1'
 'ACC$^{\C_{2}}$',  'ACC1_Phi2', 'tops_10_popSize_20_gen_50', 'tops_10_popSize_20_gen_50', 'ACC1_Phi2'
 'ACC$^{\C_{3}}$',  'ACC2_Phi1', 'tops_35_popSize_70_gen_50', 'tops_35_popSize_70_gen_50', 'ACC2_Phi1'
 'ACC$^{\C_{4}}$',  'ACC2_Phi2', 'tops_35_popSize_70_gen_50', 'tops_35_popSize_70_gen_50', 'ACC2_Phi2'
 'AFC$^{\C_{5}}$',  'AFC1_Phi1', 'tops_10_popSize_20_gen_50', 'tops_10_popSize_20_gen_50', 'AFC1_Phi1'
 'AFC$^{\C_{6}}$',  'AFC1_Phi2', 'tops_10_popSize_20_gen_50', 'tops_10_popSize_20_gen_50', 'AFC1_Phi2'
 'AFC$^{\C_{7}}$',  'AFC2_Phi1', 'tops_15_popSize_30_gen_50', 'tops_15_popSize_30_gen_50', 'AFC2_Phi1'
 'AFC$^{\C_{8}}$',  'AFC2_Phi2', 'tops_15_popSize_30_gen_50', 'tops_15_popSize_30_gen_50', 'AFC2_Phi2'
 'UUV$^{\C_{9}}$',  'UUV', 'tops_20_popInitMode_hybridGuass_popSize_40_gen_50', 'tops_20_popSize_40_gen_50', 'UUV'
 'MC$^{\C_{10}}$',  'MC',  'tops_5_popInitMode_hybridGuass_popSize_10_gen_50',  'tops_5_popSize_10_gen_50',  'MC_old'
 };
end
