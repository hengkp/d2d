% ar = arEnableData( varargin )
%
% Function which can be used to enable datasets by name or reference ar
% structure
%
% Optional inputs:
%   ar   - arStruct
%   data - either cell array of strings referring to the datasets to disable,
%          or the keyword 'all', or a reference ar structure
%
%   Note: arFindData may be used to find the names of datasets more easily
%
% Examples:
%
%   ar = arEnableData( ar, {'myData1', 'myData2'} )
%   Enables myData1 and myData2 in the ar structure.
%
%   ar = arEnableData( ar, arFindData( ar, 'myData', 'names' ) )
%   Enables all datasets containing 'myData' in the name

function ar = arEnableData( varargin )

    global ar;
    if ( isstruct( varargin{1} ) )
        ar = varargin{1};
        if ( length( varargin ) > 1 )
            varargin = varargin(2:end);
        else
            error( 'Insufficient parameters' );
        end
    end
    from = varargin{1};
    
    if ( length( varargin ) > 1 )
        verbose = varargin{2};
    else
        verbose = 0;
    end

    enableAll = 0;
    if isstruct( from )
        dataSets = {};     
        for c = 1 : length( from.model )
            for d = 1 : length( from.model(c).data )
                dataSets{end+1} = from.model(c).data(d).name;
            end
        end
    else
        if strcmp( from, 'all' )
            enableAll = 1;
        end
        
        dataSets = from;
    end
    
    for c = 1 : length( ar.model )
        for d = 1 : length( ar.model(c).data )
            if ( enableAll || ( max( strcmp( dataSets, ar.model(c).data(d).name ) ) ) )
                if ( verbose )
                    if ( max( ar.model(c).data(d).qFit ) == 0 )
                        disp( sprintf( 'Enabled dataset %s', ar.model(c).data(d).name ) );
                    else
                        disp( sprintf( 'Dataset %s already active', ar.model(c).data(d).name ) );
                    end
                end
                ar.model(c).data(d).qFit = 0 * ar.model(c).data(d).qFit + 1;
            end
        end
    end
end
