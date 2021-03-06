function F = in_fread_plexon(sFile, SamplesBounds, iChannels, precision)
% IN_FREAD_PLEXON Read a block of recordings from a Plexon file
%
% USAGE:  F = in_fread_intan(sFile, SamplesBounds=[], iChannels=[])

% % This function is using the importer developed by Benjamin Kraus (2013)
% https://www.mathworks.com/matlabcentral/fileexchange/42160-readplxfilec

% @=============================================================================
% This function is part of the Brainstorm software:
% https://neuroimage.usc.edu/brainstorm
% 
% Copyright (c)2000-2018 University of Southern California & McGill University
% This software is distributed under the terms of the GNU General Public License
% as published by the Free Software Foundation. Further details on the GPLv3
% license can be found at http://www.gnu.org/copyleft/gpl.html.
% 
% FOR RESEARCH PURPOSES ONLY. THE SOFTWARE IS PROVIDED "AS IS," AND THE
% UNIVERSITY OF SOUTHERN CALIFORNIA AND ITS COLLABORATORS DO NOT MAKE ANY
% WARRANTY, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
% MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, NOR DO THEY ASSUME ANY
% LIABILITY OR RESPONSIBILITY FOR THE USE OF THIS SOFTWARE.
%
% For more information type "brainstorm license" at command prompt.
% =============================================================================@
%
% Authors: Konstantinos Nasiotis 2018


% Parse inputs
if (nargin < 4) || isempty(precision)
    precision = 'double';
elseif ~ismember(precision, {'single', 'double'})
    error('Unsupported precision.');
end
if (nargin < 3) || isempty(iChannels)
    iChannels = 1:sFile.header.ChannelCount;
end
if (nargin < 2) || isempty(SamplesBounds)
    SamplesBounds = sFile.prop.samples;
end


%% The readPLXFileC needs to export data from time sample 1, not 0.
% Leaving it 0 would export a vector with one less element, messing the
% assignment to the matrix F later. The only effect that this change has is
% that the imported matrix would be one sample shifted, nothing else.

if SamplesBounds(1) == 0
    SamplesBounds = SamplesBounds + 1;
end

% THIS IMPORTER COMPILES A C FUNCTION BEFORE RUNNING FOR THE FIRST TIME
if exist('readPLXFileC','file') ~= 3
    current_path = pwd;
    plexon_path = bst_fileparts(which('build_readPLXFileC'));
    cd(plexon_path);
    ME = [];
    try
        build_readPLXFileC();
    catch ME
    end
    cd(current_path);
    if ~isempty(ME)
        rethrow(ME);
    end
end


%% Read the PLX file and assign it to the Brainstorm format
header = readPLXFileC(sFile.filename);
CHANNELS_SELECTED = [header.ContinuousChannels.Enabled]; % Only get the channels that have been enabled. The rest won't load any data
CHANNELS_SELECTED = find(CHANNELS_SELECTED);

nChannels = length(CHANNELS_SELECTED(iChannels));
nSamples  = diff(SamplesBounds) + 1;

data = readPLXFileC(sFile.filename, 'continuous', CHANNELS_SELECTED(iChannels)-1, 'first', SamplesBounds(1), 'num', nSamples); % This loads only the iChannels

% Initialize Brainstorm output
F = zeros(nChannels, nSamples, precision);
precFunc = str2func(precision);

ii = 0;
for iChannel = CHANNELS_SELECTED(iChannels)
    if ~isempty(data.ContinuousChannels(iChannel).Values)
        ii = ii+1;
        F(ii,:) = precFunc(data.ContinuousChannels(iChannel).Values) / 4096000; % Convert to Volts
    end
end


