%This function reshapes the serial signal according to the given format and
%applies the Fourier Transform (time domain to frequency domain)

function [demod] = ofdm_demod(serial_data, N, l)

    Nl = floor(length(serial_data)/(N+l));

    serial_data = serial_data(1:Nl*(N+l));

    demod = reshape(serial_data, (N+l), Nl);

    demod = demod((l+1):(N+l),:);

    demod = fft(demod);

end