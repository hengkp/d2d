%   arPrint
%   arPrint(3:4)
%   arPrint('sd')
%   arPrint({'para1','para2'})
% 
% print parameter values
% 
%   js      Indices of the parameters to be displayed. 'All' or omission 
%           refers to all parameters
%           (see Example below)
%
% optional arguments:
%           'initial'                   - only show initial conditions
%           'fitted'                    - only show fitted parameters
%           'constant'                  - only show constants
%           'fixed'                     - only show fixed parameters
%           'dynamic'                   - only show dynamic parameters
%           'observation'               - only show non-dynamic parameters
%           'error'                     - only show error model parameters
%           'exact'                     - match names exactly
%           'namefit'                   - display fitting option close to the name
%           'closetobound'              - show the parameters near bounds
%           'lb' followed by value      - only show values above lb
%           'ub' followed by value      - only show values below lb
%           Combinations of these flags are possible
% 
% Examples:
% arPrint('turn')
%            name                      lb       value       ub          10^value        fitted   prior
% #  22|DI | geneA_turn              |       -5      -0.41         +3 | 1      +0.39 |       1 | uniform(-5,3) 
% #  31|DI | geneB_turn              |       -5       -2.7         +3 | 1    +0.0022 |       1 | uniform(-5,3) 
% #  40|DI | geneC_turn              |       -5      -0.91         +3 | 1      +0.12 |       1 | uniform(-5,3) 
%      |   |                         |                                |              |         |      
% #  49|DI | geneD_turn              |       -5       -2.1         +3 | 1     +0.008 |       1 | uniform(-5,3) 
% #  58|DI | geneE_turn              |       -5       -2.5         +3 | 1     +0.003 |       1 | uniform(-5,3) 
% 
% arPrint(15:17)
% Parameters: # = free, C = constant, D = dynamic, I = initial value, E = error model
% 
% Example:
%            name                      lb       value       ub          10^value        fitted   prior
% #  15|D  | geneA_deg1              |       -2         -2         +3 | 1      +0.01 |       1 | uniform(-2,3) 
% #  16|D  | geneA_deg2              |       -2      +0.36         +3 | 1       +2.3 |       1 | uniform(-2,3) 
% #  17|D  | geneA_deg3              |       -2       -1.2         +3 | 1     +0.063 |       1 | uniform(-2,3) 
%
% Other examples:
% arPrint(1:4, 'constant')                  - Show the constants among the
%                                             first four parameters
% arPrint('all', 'fitted', 'dynamic')       - Show all fitted dynamic parameters
% arPrint('gene', 'observation')            - Show all observation parameters
%                                             containing the string "gene" in the name

function varargout = arPrint(js, varargin)
global ar

args = {'closetobound', 'initial', 'fixed', 'fitted', 'dynamic', 'constant', 'observation', 'error', 'lb', 'ub', 'exact', 'namefit', 'ar'};
extraArgs = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1];

if ( exist( 'js', 'var' ) )
    if ( ~isnumeric( js ) )
        if ( ismember( js, args ) )
            varargin = { js, varargin{:} }; %#ok
            clear js;
        end
    end
end
opts = argSwitch( args, extraArgs, {}, 0, varargin );

if ( opts.ar )
    if ( isstruct( opts.ar_args ) )
        arC = opts.ar_args;
    elseif ( iscell( opts.ar_args ) )
        arC = opts.ar_args{1};
        arC2 = opts.ar_args(2:end);
    else
        error( 'Invalid argument passed to arPrint ''ar''' );
    end
else
    arC = ar;
end

if(isempty(arC))
    error('please initialize by arInit')
end

if(~exist('js','var') || isempty(js))
    js = 1:length(arC.p);
elseif(islogical(js))
    js = find(js);
elseif(isnumeric(js))
    if(size(js,1)>1)
        js = js'; %should not be a row
    end
    if(sum(js==1 | js==0) ==length(js) && length(js)>1)
        js = find(js);
    end
elseif(ischar(js))
    if ( strcmp( js, 'all' ) )
        js = 1:length(arC.p);
    else
        if ( opts.exact )
            js = find(strcmp(arC.pLabel, js));
        else
            js = find(~cellfun(@isempty,regexp(arC.pLabel,js)));
        end
        if isempty(js)
            disp('Pattern not found in ar.pLabel');
            return;
        end
    end
elseif(iscell(js)) % cell of pNames
    [~,js] = intersect(arC.pLabel,js);
else
    error('Argument has to be a string or an array of indices.')
end

if(sum(isnan(js))>0 || sum(isinf(js))>0 || min(js)<1 || max(js-round(js))>eps)
    js %#ok
    warning('arPrint.m: argument js is not plausible (should be an array of indices).')
else
    if(size(js,1)~=1)
        js = js';
    end
end

pTrans = arC.p;
pTrans(arC.qLog10==1) = 10.^pTrans(arC.qLog10==1);
 
% Determine which parameters are close to their bounds
qFit = arC.qFit == 1;
arC.qCloseToBound(1:length(arC.qFit)) = 0;

ptmp = arC.p(qFit);
lbtmp = arC.lb(qFit);
ubtmp = arC.ub(qFit);

arC.qCloseToBound(qFit) = (ptmp(:) - lbtmp(:)) < arC.config.par_close_to_bound*(ubtmp(:) - lbtmp(:)) | ...
    (ubtmp(:) - ptmp(:)) < arC.config.par_close_to_bound*(ubtmp(:) - lbtmp(:));

% Additional options
if ( nargin > 1 )
    if ( opts.constant && opts.fitted )
        error( 'Incompatible flag constant and fitted' );
    end
    if ( opts.fixed && opts.fitted )
        error( 'Incompatible flag fixed and fitted' );
    end    
    if ( opts.constant && opts.fixed )
        error( 'Incompatible flag constant and fixed' );
    end
    if ( opts.observation && opts.dynamic )
        error( 'Incompatible flag observation and dynamic' );
    end    

    if ( opts.fixed )
        js = js( arC.qFit( js ) == 0 );
    end
    if ( opts.fitted )
        js = js( arC.qFit( js ) == 1 );
    end
    if ( opts.constant )
        js = js( arC.qFit( js ) == 2 );
    end
    if ( opts.dynamic )
        js = js( arC.qDynamic( js ) == 1 );
    end
    if ( opts.observation )
        js = js( arC.qDynamic( js ) == 0 );
    end
    if ( opts.error )
        js = js( arC.qError( js ) == 1 );
    end    
    if ( opts.initial )
        js = js( arC.qInitial( js ) == 1 );
    end
    if ( opts.ub )
        js = js( arC.p(js) < opts.ub );
    end
    if ( opts.lb )
        js = js( arC.p(js) > opts.lb );
    end
    if ( opts.closetobound )
        js = js( arC.qCloseToBound(js) );
    end
end

if nargout>0
    varargout{1} = js;
end

maxlabellength = max(cellfun(@length, arC.pLabel(js)));
if ( opts.namefit )
    maxlabellength = maxlabellength + 2;
end

arFprintf(1, 'Parameters: # = free, C = constant, D = dynamic, I = initial value, E = error model\n\n');

printHead;
for j=1:length(js)
    printPar(js(j), arC, arC.qCloseToBound(js(j)));
    if ( exist('arC2', 'var' ) )
        for jA = 1 : numel( arC2 )
            ID = arFindPar( arC2{jA}, arC.pLabel{js(j)}, 'exact' );
            if ( ~isempty( ID ) )
                printPar(ID, arC2{jA}, arC2{jA}.qCloseToBound(ID));
            end
        end
    end
	if(mod(j,10)==0 && j<length(js))
		arFprintf(1, ['     |   | ' arExtendStr('', maxlabellength) ' |                                |              |         |      \n']);
	end
end

    function printHead
        strhead = ['     |   | ' arExtendStr('name', maxlabellength) ' | lb       value       ub        | 10^value      | fitted | prior\n'];
        strhead = strrep(strhead, '|', ' ');
        arFprintf(1, strhead);
    end

    function printPar(j, arC, qclosetobound)
        strdyn = ' ';
        if(arC.qDynamic(j))
            strdyn = 'D';
        end
        strerr = ' ';
        if(arC.qError(j))
            strerr = 'E';
        end
        strinit = ' ';
        if(arC.qInitial(j))
            strinit = 'I';
        end
        
        if(qclosetobound)
            outstream = 2;
        else
            outstream = 1;
        end
        if(arC.qFit(j)==2)
            fit_flag = 'C';
        else
            fit_flag = '#';
        end
        if ( opts.namefit && (arC.qFit(j) ~= 1) )
            arFprintf(1, outstream, '%s%4i|%s%s%s| %s | %+8.2g   %+8.2g   %+8.2g | %i   %+8.2g | %7i | %s \n', ...
                fit_flag, j, strdyn, strinit, strerr, arExtendStr(['(' arC.pLabel{j} ')'], maxlabellength), arC.lb(j), arC.p(j), arC.ub(j), arC.qLog10(j), pTrans(j), arC.qFit(j), priorStr(j));
        else
            arFprintf(1, outstream, '%s%4i|%s%s%s| %s | %+8.2g   %+8.2g   %+8.2g | %i   %+8.2g | %7i | %s \n', ...
                fit_flag, j, strdyn, strinit, strerr, arExtendStr(arC.pLabel{j}, maxlabellength), arC.lb(j), arC.p(j), arC.ub(j), arC.qLog10(j), pTrans(j), arC.qFit(j), priorStr(j));
        end
        
    end

    function str = priorStr(j)
        if(arC.type(j) == 0)
            str = sprintf('uniform(%g,%g)', arC.lb(j), arC.ub(j));
        elseif(arC.type(j) == 1)
            str = sprintf('normal(%g,%g^2)', arC.mean(j), arC.std(j));
        elseif(arC.type(j) == 2)
            str = sprintf('uniform(%g,%g) with soft bounds', arC.lb(j), arC.ub(j));
        elseif(arC.type(j) == 3)
            str = sprintf('L1(%g,%g)', arC.mean(j), arC.std(j));
        end
    end
end
