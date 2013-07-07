% This function print shows the reconstructed greyscale image
function imageReconstructed = view_image(bitStream, imgH, imgW)

    % Slice the needed part to recostruct the picture
    bitStream = bitStream(1:imgW*imgH*8);

    % Generate matrix of pixels rows and 8-bits columns
    byteSequence = reshape( bitStream, 8, length(bitStream)/8 )';

    % Create a powers of 2 constant vector
    temp = [128 64 32 16 8 4 2 1];

    vectBin2Dec = repmat(temp, size(byteSequence,1), 1);

    % Regenerate the pixels
    pixelSeq = sum(byteSequence.*vectBin2Dec,2);

    imageReconstructed = reshape(pixelSeq, imgH, imgW);

    % Show the reconstructed image
    imageview(imageReconstructed);

end