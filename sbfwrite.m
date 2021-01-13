function sbfwrite(XA, file, nva)
% SBFWRITE Write point cloud in simple binary file format used by CloudCompare.
% ------------------------------------------------------------------------------
% DESCRIPTION/NOTES
% * Format definition: https://www.cloudcompare.org/doc/wiki/index.php?title=SBF
% * Shifts (s=...) and precisions (p=...) of scalar fields are not implemented.
% ------------------------------------------------------------------------------
% INPUT
% 1 [XA]
%   Array of dimension n-by-m, where each of the m columns correspond to a 
%   single point with 3 coordinates (rows 1,2,3) and n-3 scalar fields.
%
% 2 [file]
%   Path to sbf file.
%
% 3 ['GlobalShift', globalShift]
%   1-by-3 vector containing the global shift of the point coordinates in XA.
%
% 4 ['SFNames', SFNames]
%   Names of scalar fields in cell, e.g. {'nx' 'ny' 'nz'}.
% ------------------------------------------------------------------------------
% EXAMPLES
% 1 Write sbf file.
%   XA = rand(5, 1000); % 3 coordinate and 2 scalar field values for each point.
%   sbfwrite(XA, fullfile(tempdir, 'file.sbf'), 'SFNames', {'SF1' 'SF2'});
% ------------------------------------------------------------------------------
% philipp.glira@gmail.com
% ------------------------------------------------------------------------------

    arguments
        XA single {mustBeNumeric, mustBeAtLeastOfDimNbyM(XA, 3, 1)}
        file (1,:) {mustBeTextScalar, checkFile(file)} % char or string
        nva.GlobalShift (1,3) {mustBeNumeric} = [0 0 0]
        nva.SFNames (1,:) {mustBeText, checkSFNames(nva.SFNames, XA)} = ''
    end
    
    writeAsciiFile(XA, file, nva);
    writeBinaryFile(XA, file+".data", nva);
    
end

function writeAsciiFile(XA, file, nva)
% WRITEASCIIFILE Write header metadata to '.sbf' ascii file.

    fid = fopen(file, "wt");
    if fid == -1
        error("Can not open '%s'!", file);
    end
    
    fprintf(fid, "[SBF]\n");
    fprintf(fid, "Points=%d\n", size(XA,2));
    fprintf(fid, "GlobalShift=%f, %f, %f\n", nva.GlobalShift);
    fprintf(fid, "SFCount=%d\n", size(XA,1)-3);
    for i = 1:size(XA,1)-3
        fprintf(fid, "SF%d=%s\n", i, nva.SFNames{i});
    end
    
    fclose(fid);

end

function writeBinaryFile(XA, file, nva)
% WRITEBINARYFILE Write point cloud data to '.sbf.data' binary file.

    fid = fopen(file, 'w', 'b');
    if fid == -1
        error("Can not open '%s'!", file);
    end
    
    % Write header
    fwrite(fid, 42, 'uint8');
    fwrite(fid, 42, 'uint8');
    fwrite(fid, size(XA,2), 'uint64');
    fwrite(fid, size(XA,1)-3, 'integer*2');
    fwrite(fid, nva.GlobalShift(1), 'double');
    fwrite(fid, nva.GlobalShift(2), 'double');
    fwrite(fid, nva.GlobalShift(3), 'double');
    fwrite(fid, zeros(28,1), 'uint8');
    
    % Write point cloud data
    fwrite(fid, XA, 'single');
    
    fclose(fid);

end

function mustBeAtLeastOfDimNbyM(array, n, m)
% MUSTBEATLEASTOFDIMNBYM Check if the given array is at least of dimension n-by-m.

    arguments
        array
        n (1,1) {mustBeInteger}
        m (1,1) {mustBeInteger}
    end

    assert(size(array,1) >= n, "Array must have at least %d rows!", n);
    assert(size(array,2) >= m, "Array must have at least %d rows!", m);

end

function checkFile(file)
% CHECKFILE Additional checks of 'file' argument.

    assert(endsWith(file, ".sbf"), "File path must end with '.sbf'!");
    
end

function checkSFNames(SFNames, XA)
% CHECKSFNAMES Additional checks of 'checkSFNames' argument.
    
    % Check the correct number of SFNames 
    SFCount = size(XA,1)-3;
    if SFCount > 0
        if isempty(SFNames) | SFNames == ""
           error("The names of the scalar fields are not specified!")
        end
        if SFCount ~= numel(SFNames)
           error("Wrong number of scalar field names!")
        end
    end

end