% pop_limo() - prepare and convert EEGLAB data and structure to be
%              processed by LIMO.
%
% Usage:
%   >> STUDY = pop_limo( STUDY, ALLEEG, 'key', val)
%   >> STUDY = pop_limo( STUDY, ALLEEG, 'dat', 'key', val)
%   >> STUDY = pop_limo( STUDY, ALLEEG, 'ica', 'key', val)
%
% Inputs:
%   STUDY        - an EEGLAB STUDY set of loaded EEG structures
%   ALLEEG       - ALLEEG vector of one or more loaded EEG dataset structures
%   'dat'|'ica'  - show the interface for data channels or for ICA. The
%                  default is to use data.
%
% Optional inputs: same as std_limo()
%
% Graphical interface:
%   "See GLM factors" - [push button] See all the GLM factors or columns in
%                   the design matrix. This list depends on your study
%                   design. Adding contrast will change this list. In
%                   practice, it is important to understand that every
%                   single factor will be fitted by the GLM, and the choice
%                   of these factors is critical. It is recommended to
%                   include as many factors as possible, especially because
%                   this allows you to define new contrast later on without
%                   having to recompute the GLM on each subject (as long as
%                   these new contrast do not involve new factors).
%
%  "Interaction model for categorical indep. var." - When using more than 
%                   one categorical variable, clicking this option forces
%                   to have factors which are the conjonction of the
%                   different independent var. values. This is useful only 
%                   if you want to calculate interactions at the subject.
%                   The 'best' option is typically to have a design with
%                   all conditions (no factors) and create factors at the
%                   group level.
%
%  "Split regressions (continuous indep. var.)" - This options allows to
%                   split continuous variables for the different
%                   categorical variables. This is useful to compute 
%                   interaction between continuous and categorical
%                   variables. 
%
%  "Input data to use for the GLM" - [pop up menu] measure to use as input
%                   for the GLM. Currently, only "ERP" and "spectrum" are 
%                   supported.
%
%  "Optimization method" - [pop up meny] may be Ordinary Least Square (OLS) 
%                   or Weighted Least Square (WTS). WTS should be used as it 
%                   is more robust. OLS is a standard solution and WTS is a
%                   solution that automatically exclude some outlier trials.
%
%  "Options"        - [edit box] additional options. These are given
%                   directly as input to the std_limo.m function. They may
%                   be ['freqlim', value] frequency trimming in Hz or 
%                   ['timelim', value] time trimming in millisecond. These
%                   allow to speed up computation by not including all the
%                   data as input. Example: 'timelim', [-50 650] only
%                   include data within the -50 ms and 650 ms for ERPs.
%
% "Erase previous model" - [checkbox] erase previous model for this
%                   measure.
%
% Outputs:
%   STUDY       - an EEGLAB STUDY set of loaded EEG structures
%
% Author: Arnaud Delorme, SCCN, UCSD, 2015-
%         Cyril Pernet, LIMO Team - edit info and defaults
%
% See also: std_limo()

% Copyright (C) Arnaud Delorme
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

function [STUDY,com] = pop_limo(STUDY, ALLEEG, measureflag, varargin)

if nargin < 2
    help pop_limo;
    return;
end

com = '';
if nargin > 2
    if strcmpi(measureflag,'dat')
        measureflagindx = 1;
    elseif strcmpi(measureflag,'ica')
        measureflagindx = 2;
    else
        varargin = { measureflag varargin{:} };
        measureflagindx = 1;
    end
else
    measureflagindx = 1;
end
    
if nargin < 4
    dataMeasures = { 'ERP' 'Spectrum' };
    fileMeasures = { 'daterp' 'datspec'; 'icaerp' 'icaspec' };
    methods      = { 'OLS' 'WLS' };
    cb_measure   = [ 'if get(gcbo, ''value'') == 1,' ...
                     '   set(findobj(gcbf, ''tag'', ''options''), ''string'', '''');' ...
                     'else,' ...
                     '   set(findobj(gcbf, ''tag'', ''options''), ''string'', ''''''freqlim'''', [1 25]'');' ...
                     'end;' ];
    cb_listfactors = [ 'pop_listfactors(STUDY, ''gui'', ''on'', ' ...
                               '''splitreg''   , fastif(get(findobj(gcbf, ''tag'', ''splitreg''   ), ''value''), ''on'', ''off''),' ...
                               '''interaction'', fastif(get(findobj(gcbf, ''tag'', ''interaction''), ''value''), ''on'', ''off''));' ];
    uilist = { ...
        {'style' 'text'       'string' 'LInear MOdeling of EEG data' 'fontweight' 'bold' 'fontsize', 12} ...
        {'style' 'pushbutton' 'string' 'See GLM variables' 'callback' cb_listfactors } ...
        {'style' 'checkbox'   'string' 'Interaction model for categorical indep. var.' 'value' 0 'tag' 'interaction' } ...
        {'style' 'checkbox'   'string' 'Split regressions (continuous indep. var.)' 'tag' 'splitreg' } {} ...
        {'style' 'text'       'string' 'Input data to use for the GLM' } ...
        {'style' 'popupmenu'  'string' dataMeasures 'tag' 'measure' 'callback' cb_measure} ...
        {'style' 'text'       'string' 'Optimization method' } ...
        {'style' 'popupmenu'  'string' methods 'tag' 'method' } ...
        {'style' 'text'       'string' 'Options' } ...
        {'style' 'edit'       'string' '' 'tag' 'options' } ...
        {'style' 'checkbox'   'string' 'Erase previous model' 'tag' 'erase' 'value' true } ...
        };
    
    cline = [1.1 0.8];
    geometry = { [1.6 1] 1 1 1 cline cline cline 1 };
    geomvert = [ 1 1 1     1 1 1     1     1 ];
        
    [out_param userdat tmp res] = inputgui( 'geometry' , geometry, 'uilist', uilist, 'geomvert', geomvert, ...
                                            'title', 'LInear MOdeling of EEG data -- pop_limo()', 'helpcom', 'pophelp(''pop_limo'');');
    if isempty(res), return; end
    opttmp  = eval( [ '{ ' res.options ' }' ]);
    if length(opttmp) > 0 && isnumeric(opttmp{1})
        error([ 'Wrong options. Options must be in the format' 10 '''key'', val. For example ''timelim'', [-100 600]' ]);
    end
    options = { 'method' methods{res.method} 'measure' fileMeasures{measureflagindx,res.measure} opttmp{:} ...
                'erase'       fastif(res.erase, 'on', 'off') ...
                'splitreg'    fastif(res.splitreg, 'on', 'off') ...
                'interaction' fastif(res.interaction, 'on', 'off') };
else
    options = varargin;
end

[STUDY tmp] = std_limo(STUDY, ALLEEG, options{:});
com = sprintf('pop_limo(STUDY, ALLEEG, %s);', vararg2str(options));
