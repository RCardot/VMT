function [zPathName,zFileName,savefile,A,z] = VMT_ReadFiles_SonTek(zPathName,zFileName)
% Read in multiple MAT output files from SonTek RSL v1.5-3.60.
%
% Added save path functionality (PRJ, 6-23-10)
% (adapted from code by J. Czuba)
%
% See also: parseSonTekVMT (utils folder)
%
% Frank L. Engel, USGS 
% Last modified: 03/27/2014



%% Read in multiple MAT files Files
% This program reads in multiple ASCII text files into a single structure.

if ischar(zFileName)
    zFileName = {zFileName};
elseif iscellstr(zFileName)
    zFileName = sort(zFileName);       
end
%msgbox('Loading Data...','VMT Status','help','replace')

%% Read in Selected Files
% Initialize the data structure
z = length(zFileName);
A = initStructure(z);

% Begin master loop
for zi=1:z
    % Open txt data file
    fileName = fullfile(zPathName,zFileName{zi});


    % parseSonTekVMT reads the data from an RSL MAT output file and puts
    % the data in a Matlab data structure with major groups of:
    % Sup - supporing data
    % Wat - water data
    % Nav - navigation data including GPS.
    % Sensor - Sensor data
    % Q - discharge related data

    try
        [A(zi)]=parseSonTekVMT(fileName);
        
        [~,file_name,extension] = fileparts(fileName);
        new_message = strrep(['Loading file ' file_name extension],'_','\_');
%         if ishandle(h_waitbar)
%             waitbar(zi/z,h_waitbar,new_message)
%         else
%             h_waitbar = waitbar(zi/z,new_message,'Name','Loading Files');
%         end

    catch err
        
		erstg = {'                                                      ',...
                 'An unknown error occurred when reading the ASCII file.',...
                 'Occasionally this occurs due to a corrupt ASCII file with',...
                 'formatting errors. Please regenerate the ASCII file and ',...
                 'retry loading into VMT. An error may also occur if there ',...
                 'are white spaces or special characters (e.g. *?<>|) in ',...
                 'the filenames or paths. Ensure no such spaces or ',...
                 'characters exist and try loading the files again.'};
        
		if isdeployed
        errLogFileName = fullfile(pwd,...
            ['errorLog' datestr(now,'yyyymmddHHMMSS') '.txt']);
        msgbox({erstg;...
			['  Error code: ' err.identifier];...
            ['Error details are being written to the following file: '];...
            errLogFileName},...
            'VMT Status: Unexpected Error',...
            'error');
        fid = fopen(errLogFileName,'W');
        fwrite(fid,err.getReport('extended','hyperlinks','off'));
        fclose(fid);
        rethrow(err)
    else
        msgbox(['An unexpected error occurred. Error code: ' err.identifier],...
            'VMT Status: Unexpected Error',...
            'error');
        rethrow(err);
    end
    end
    
    % Check the units to ensure they are metric
    
    if ~strcmp(A(zi).Sup.units(1,:),'cm')
        erstg = {'                                                      ',...
                 'Units in ASCII file are not metric.  VMT only accepts data'...
                 'in metric units.  Please change the units in WinRiver II'...
                 'and export your ASCII files again before reloading into VMT.'};
        errordlg([zFileName(zi) erstg],'VMT Status','replace');
        error('VMT:unitsChk', 'Input not in metic units')
    end

end

% Get rid of the waitbar
% if ishandle(h_waitbar)
%     delete(h_waitbar)
% end

% Save data returned by tfile to .mat with same prefix as ASCII 
[file_root_name,the_rest] = strtok(zFileName,'.');
for i = 1:length(zFileName)
    d1 = file_root_name{i};
    date{i} = d1(1:8);
    time{i} = d1(9:end);
end

save_dir = fullfile(zPathName,'VMTProcFiles');
[~,mess,~] = mkdir(save_dir); 
% disp(mess)

savefile = [date{1} '_s' time{1} '_e' time{end} '.mat'];
savefile = fullfile(save_dir,savefile);

%%%%%%%%%%%%%%%%%%%%%%
% Embedded Functions %
%%%%%%%%%%%%%%%%%%%%%%

function A = initStructure(z)
   Sup = struct('absorption_dbpm',{}, ...
                'bins',{}, ...
                'binSize_cm',{}, ...
                'nBins',{}, ...
                'blank_cm',{}, ...
                'draft_cm',{}, ...
                'ensNo',{}, ...
                'nPings',{}, ...
                'noEnsInSeg',{}, ...
                'noe',{}, ...
                'note1',{}, ...
                'note2',{}, ...
                'intScaleFact_dbpcnt',{}, ...
                'intUnits',{}, ...
                'vRef',{}, ...
                'wm',{}, ...
                'units',{}, ...
                'year',{}, ...
                'month',{}, ...
                'day',{}, ...
                'hour',{}, ...
                'minute',{}, ...
                'second',{}, ...
                'sec100',{}, ...
                'timeElapsed_sec',{}, ...
                'timeDelta_sec100',{});
   Wat = struct('binDepth',{}, ...
                'backscatter',{}, ...
                'beamFreq',{}, ...
                'beamMode',{}, ...
                'vDir',{}, ...
                'vMag',{}, ...
                'vEast',{}, ...
                'vError',{}, ...
                'vNorth',{}, ...
                'vVert',{}, ...
                'percentGood',{});
   Nav = struct('bvEast',{}, ...
                'bvError',{}, ...
                'bvNorth',{}, ...
                'bvVert',{}, ...
                'depth',{}, ...
                'dsDepth',{}, ...
                'dmg',{}, ...
                'length',{}, ...
                'totDistEast',{}, ...
                'totDistNorth',{}, ...
                'altitude',{}, ...
                'altitudeChng',{}, ...
                'gpsTotDist',{}, ...
                'gpsVariable',{}, ...
                'gpsVeast',{}, ...
                'gpsVnorth',{}, ...
                'lat_deg',{}, ...
                'long_deg',{}, ...
                'nSats',{}, ...
                'hdop',{});
   Sensor = struct('sensor_type',{}, ...
                   'pitch_deg',{}, ...
                   'roll_deg',{}, ...
                   'heading_deg',{}, ...
                   'temp_degC',{});
     Q = struct('endDepth',{}, ...
                'endDist',{}, ...
                'bot',{}, ...
                'end',{}, ...
                'meas',{}, ...
                'start',{}, ...
                'top',{}, ...
                'unit',{}, ...
                'startDepth',{}, ...
                'startDist',{});
            A(z).Sup = Sup;
            A(z).Wat = Wat;
            A(z).Nav = Nav;
            A(z).Sensor = Sensor;
            A(z).Q = Q;
            
            % [EOF] initStructure
