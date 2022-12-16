function [header, data] = sbfread(file)
% SBFREAD Read point cloud in simple binary file format used by CloudCompare.
% ------------------------------------------------------------------------------
% DESCRIPTION/NOTES
% * Format definition: https://www.cloudcompare.org/doc/wiki/index.php?title=SBF
% ------------------------------------------------------------------------------
% INPUT
% 1 [file]
%   Path to sbf file.
% ------------------------------------------------------------------------------
% OUTPUT
% 1 [header]
%   Structure containing the header metadata from the '.sbf' ascii file.
%
% 2 [data]
%   Structure containing the point cloud data from the '.sbf.data' binary file.
% ------------------------------------------------------------------------------
% EXAMPLES
% 1 Read sbf file.
%   [header, data] = sbfread('Lion.sbf');
% ------------------------------------------------------------------------------
% philipp.glira@gmail.com
% ------------------------------------------------------------------------------

    arguments
        file {mustBeFile}
    end

    header = readAsciiFile(file);
    data = readBinaryFile([file '.data']);

    compareDuplicateEntries(header, data);

end

function header = readAsciiFile(file)
% READASCIIFILE Read header metadata from '.sbf' ascii file.

    header = struct;

    % Open file
    fid = fopen(file, 'rt');
    if fid == -1
        error('Can not read ''%s''!', file);
    end
    header.file = file;

    % Check first line
    tline = fgetl(fid);
    if ~strcmpi(tline, '[SBF]')
        error('''%s'' does not contain ''[SBF]'' on the first line!', file);
    end

    % Read rest of file into structure
    tline = fgetl(fid);
    noLine = 2;
    while ischar(tline)
       tline = strtrim(tline); % remove any leading/trailing spaces
       if ~isempty(tline) % skip empty lines
           idxEqual = strfind(tline, '=');
           if ~isempty(idxEqual)
               field = tline(1:idxEqual(1)-1);
               if strcmp(field, 'GlobalShift')
                   globalShiftCell = textscan(tline(idxEqual(1)+1:end), '%f', 'Delimiter', ',');
                   header.(field) = globalShiftCell{1}';
               elseif matches(field, "SF" + digitsPattern) % e.g. SF1
                   entries = textscan(tline(idxEqual(1)+1:end), '%s', 'Delimiter', ',');
                   header.(field).name = entries{1}{1};
                   if numel(entries{1}) > 1 % if the options 'p=' or 's=' are defined
                       for idxEntry = 2:numel(entries{1})
                            [attribute, value] = strtok(entries{1}{idxEntry}, '=');
                            value = value(2:end); % remove '='
                            if attribute == 's'
                                header.(field).(attribute) = str2double(value);
                            else
                                header.(field).(attribute) = value;
                            end
                       end
                   end
               else
                   header.(field) = str2double(tline(idxEqual(1)+1:end));
               end
           else
               warning('Can not interpret line %d in ''%s''', noLine, file);
           end
       end
       tline = fgetl(fid);
       noLine = noLine+1;
    end

    fclose(fid);

end

function data = readBinaryFile(file)
% READBINARYFILE Read point cloud data from '.sbf.data' binary file.

    data = struct;

    % Open file
    fid = fopen(file, 'r', 'b');
    if fid == -1
        error('Can not read ''%s''!', file);
    end
    data.file = file;

    % Read header
    fseek(fid, 2, 'bof');
    data.Points = fread(fid, 1, 'uint64');
    data.SFCount = fread(fid, 1, 'integer*2');
    data.GlobalShift = fread(fid, [1,3], 'double');

    % Read point cloud data
    fseek(fid, 64, 'bof');
    data.XA = fread(fid, [3+data.SFCount data.Points], 'single');

    fclose(fid);

end

function compareDuplicateEntries(header, data)
% COMPAREDUPLICATEENTRIES Compare duplicate entries in header and data structure.

    entriesToCompare = ["Points" "SFCount" "GlobalShift"];

    for entry = entriesToCompare

        if ~isfield(header, entry)
            warning('File ''%s'' does not contain the entry ''%s''.', header.file, entry);
            continue;
        end

        if ~isfield(data, entry)
            warning('File ''%s'' does not contain the entry ''%s''.', data.file, entry);
            continue;
        end

        if header.(entry) ~= data.(entry)
            warning('Values for ''%s'' in header file and data file are not the same.', entry);
        end

    end

end