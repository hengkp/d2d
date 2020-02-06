% arLoadParsPEtab(filename)
%
% Loads parameters from filename into ar
% 
%   filename    is the name of the *.tsv file which will be loaded in the
%               ar-struct
%
% This is required to load additional information about parameters from
% PEtab data standard
% 
% Example
%     arLoadParsPEtab('parameters_Boehm_JProteomeRes2014.tsv')
% 
% References
%   - https://github.com/ICB-DCM/PEtab/blob/master/doc/documentation_data_format.md

function arLoadParsPEtab(filename)

global ar
    
if ~contains(filename,'.tsv')
    if ~contains(filename,'.')
        filename = [filename '.tsv'];
    else
        error('this file type is not supported!')
    end
end

T = tdfread(filename);
[BothPars, ia, ib] = intersect(ar.pLabel,cellstr(T.parameterID));

T.qLog10 = nan(size(T.nominalValue));
T.qLog10(contains(string(T.parameterScale),'lin')) = 0;
T.qLog10(contains(string(T.parameterScale),'log10')) = 1;

if any(isnan(T.qLog10))
    warning([T.parameterScale(isnan(T.parameterScale)) ' is not yet implemented as qLog. ar.qLog10 is set to 0.'])
end

% arSetPars(pLabel, [p], [qFit], [qLog10], [lb], [ub], [type], [meanp], [stdp])
fLogTrafo = @(x)(1-T.qLog10(ib)) .* x(ib) + T.qLog10(ib) .* log10(x(ib)); % apply log10 trafo if flag is set. (Values given are on lin scale)
arSetPars(ar.pLabel(ia), fLogTrafo(T.nominalValue), T.estimate(ib), T.qLog10(ib), fLogTrafo(T.lowerBound), fLogTrafo(T.upperBound))

% this is currently under development on the PEtab side.
if isfield(T,'priorType')
for i=1:length(BothPars)
    if ischar(T.priorType(ib(i)))
        if isnumeric(T.priorParameters)
            arSetPrior(ia(i),T.priorType(ib(i)),T.priorParameters(ib(i),1),T.priorParameters(ib(i),2))
        else
            arSetPrior(ia(i),T.priorType(ib(i)))
        end
    end
end
end