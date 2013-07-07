%This function modulates the input signal according to a given QAM mode.
%sequence - vector of binary numbers representing the signal
%qamm - mode of QAM (4, 16 or 64)

function [complex_number] = qa_mod(sequence, qamm)

    leng = length(sequence);

    if (qamm == 4)
        
        v1 = sequence(1:2:leng);
        v2 = sequence(2:2:leng);
        real_part = 2*v1-1;
        imag_part = 2*v2-1;

        complex_number = complex(real_part,imag_part);
        
    elseif (qamm == 16)
        
        v1 = sequence(1:4:leng);
        v2 = sequence(2:4:leng);
        v3 = sequence(3:4:leng);
        v4 = sequence(4:4:leng);

        real_part = (-1).^not(v1);
        imag_part = (-1).^not(v2);
        real_part = real_part + v3.*2.*(-1).^not(v1);
        imag_part = imag_part + v4.*2.*(-1).^not(v2);

        complex_number = complex(real_part,imag_part);
        
    elseif (qamm == 64)
        
        v1 = sequence(1:6:leng);
        v2 = sequence(2:6:leng);
        v3 = sequence(3:6:leng);
        v4 = sequence(4:6:leng);
        v5 = sequence(5:6:leng);
        v6 = sequence(6:6:leng);

        real_part = (-1).^not(v1);
        imag_part = (-1).^not(v2);
        real_part = real_part + v3.*4.*(-1).^not(v1);
        imag_part = imag_part + v4.*4.*(-1).^not(v2);
        real_part = real_part + not(xor(v3,v5)).*2.*(-1).^not(v1);
        imag_part = imag_part + not(xor(v4,v6)).*2.*(-1).^not(v2);

        complex_number = complex(real_part,imag_part);
        
    else
        disp('Invalid QAM mode.');
        return;
    end
end