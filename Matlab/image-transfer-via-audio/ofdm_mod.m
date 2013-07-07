%This function applies the Inverse Fourier Transform on signal (frequency
%domain to time domain) and serialize the result.

function [mod] = ofdm_mod(packet, l)
    %perform ifft on packet
    packet = ifft(packet);

    %concatenate cycle prefix of packet with packet itself
    packet = [packet((size(packet,1)-l+1):size(packet,1),:);packet];

    %serialize packet
    mod = reshape(packet, 1, size(packet,1)*size(packet,2));

end