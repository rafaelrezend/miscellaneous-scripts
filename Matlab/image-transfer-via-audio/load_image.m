% This funtion retuns the stream and size of the image
function [stream, rows, cols] = load_image(filename)

    img = imread(filename);
    % Get dimensions
    [rows cols] = size(img);
    % Convert rgb to gray
    img = rgb2gray(img);

    % Convert from matrix to vector
    img = img(:);

    % Substract 48 from every single pixel
    stream = ( dec2bin(img,8) - 48 )';

    % Convert from matrix to vector and return the final stream
    stream = stream(:)';

end