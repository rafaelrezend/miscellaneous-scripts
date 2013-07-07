%generate a training frame
function [training] = generate_training(size)

    key = ones(1,8);
    training = zeros(1,size);
    for i = 1:size;
        training(i) = 1 - 2* key(8);
        key = circshift(key,[0 1]);
        key(1) = xor(xor(key(1),key(7)), xor(key(6),key(5)));
    end
    training = (training+1)./2;
    
end