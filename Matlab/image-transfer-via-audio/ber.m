%This function calculates the error rate between original signal and
%demodulated signal.

function [rate] = ber(original, demodulated)

    wrong_bits = sum(xor(original,demodulated));
    rate = wrong_bits/length(original)*100;

end