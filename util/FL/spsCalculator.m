function spsScore = spsCalculator(ep, np, ef, nf, spsMetric)
% spsCalculator function returns the suspiciousness score based on ep, np, ef, nf and sps_metric.
%
% Inputs:
%   ep: passed and topk
%   np: passed and not topk
%   ef: failed and topk
%   nf: failed and not topk
%   spsMetric: suspiciousness metrics, including alpha, beta and minus (alpha-beta) version
% Outputs:
%   spsScore: suspiciousness score

if strcmp(spsMetric, 'Tarantula')
    spsScore = (ef./(ef+nf)) ./ ((ef./(ef+nf)) + (ep./(ep+np)));
elseif strcmp(spsMetric, 'Ochiai')
    spsScore = ef ./ sqrt((ef+nf) .* (ef+ep));
elseif strcmp(spsMetric, 'D2')
    spsScore = (ef.^2) ./ (ep+nf);
elseif strcmp(spsMetric, 'D3')
    spsScore = (ef.^3) ./ (ep+nf);
elseif strcmp(spsMetric, 'Jaccard')
    spsScore = ef ./ (ef+nf+ep);
elseif strcmp(spsMetric, 'Kulczynski1')
    spsScore = ef ./ (nf+ep);
elseif strcmp(spsMetric, 'Kulczynski2')
    spsScore = 0.5 * (ef./(ef+nf) + ef./(ef+ep));
elseif strcmp(spsMetric, 'Op2')
    spsScore = ef - (ep ./ (ep+np+1));

    % elseif strcmp(sps_metric, 'betaTarantula')
    %     sps_score = (nf/(nf+ef))/((nf/(nf+ef))+(np/(np+ep)));
    % elseif strcmp(sps_metric, 'betaOchiai')
    %     sps_score = nf/sqrt((nf+ef)*(nf+np));
    % elseif strcmp(sps_metric, 'betaDstar2')
    %     sps_score = (nf^2)/(np+ef);
    % elseif strcmp(sps_metric, 'betaDstar3')
    %     sps_score = (nf^3)/(np+ef);
    % elseif strcmp(sps_metric, 'betaJaccard')
    %     sps_score = nf/(nf+ef+np);
    % elseif strcmp(sps_metric, 'betaKulczynski1')
    %     sps_score = nf/(ef+np);
    % elseif strcmp(sps_metric, 'betaKulczynski2')
    %     sps_score = 0.5 * (nf/(nf+ef) + nf/(nf+np));
    % elseif strcmp(sps_metric, 'betaOp2')
    %     sps_score = nf-(np/(np+ep+1));
    % elseif strcmp(sps_metric, 'minusTarantula')
    %     sps_score = (ef/(ef+nf))/((ef/(ef+nf))+(ep/(ep+np))) - (nf/(nf+ef))/((nf/(nf+ef))+(np/(np+ep)));
    % elseif strcmp(sps_metric, 'minusOchiai')
    %     sps_score = ef/sqrt((ef+nf)*(ef+ep)) - nf/sqrt((nf+ef)*(nf+np));
    % elseif strcmp(sps_metric, 'minusDstar2')
    %     sps_score = (ef^2)/(ep+nf) - (nf^2)/(np+ef);
    % elseif strcmp(sps_metric, 'minusDstar3')
    %     sps_score = (ef^3)/(ep+nf) - (nf^3)/(np+ef);
    % elseif strcmp(sps_metric, 'minusJaccard')
    %     sps_score = ef/(ef+nf+ep) - nf/(nf+ef+np);
    % elseif strcmp(sps_metric, 'minusKulczynski1')
    %     sps_score = ef/(nf+ep) - nf/(ef+np);
    % elseif strcmp(sps_metric, 'minusKulczynski2')
    %     sps_score = 0.5 * (ef/(ef+nf) + ef/(ef+ep)) - 0.5 * (nf/(nf+ef) + nf/(nf+np));
    % elseif strcmp(sps_metric, 'minusOp2')
    %     sps_score = ef-(ep/(ep+np+1)) - (nf-(np/(np+ep+1)));
else
    error('Check your suspiciousness metrics!');
end
end