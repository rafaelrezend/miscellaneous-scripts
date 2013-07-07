%This function demodulates the input signal according to a given QAM mode.
%signal - vector of complex numbers representing the signal
%qamm - mode of QAM (4, 16 or 64)

function [demodulated] = qa_demod(signal, qamm)

    real_after = real(signal);
    imag_after = imag(signal);
    
    if (qamm == 4)
        
        leng = length(real_after).*2;
        
        demodulated = zeros(1,leng);

        for count=1:leng/2,
            if (real_after(count) > 0) demodulated(count*2-1)=1;
            else demodulated(count*2-1)=0;
            end
            if (imag_after(count) > 0) demodulated(count*2)=1;
            else demodulated(count*2)=0;
            end
        end
    
    elseif (qamm == 16)
    
        leng = length(real_after).*4;

        demodulated = zeros(1,leng);

        for count=1:leng/4,
            if (real_after(count) > 0) demodulated(count*4-3)=1;
            else demodulated(count*4-3)=0;
            end
            if (imag_after(count) > 0) demodulated(count*4-2)=1;
            else demodulated(count*4-2)=0;
            end
            if (abs(real_after(count)) > 2) demodulated(count*4-1)=1;
            else demodulated(count*4-1)=0;
            end
            if (abs(imag_after(count)) > 2) demodulated(count*4)=1;
            else demodulated(count*4)=0;
            end
        end
        
    elseif (qamm == 64)
    
        leng = length(real_after).*6;

        demodulated = zeros(1,leng);

        for count=1:leng/6,
            if (real_after(count) > 0) demodulated(count*6-5)=1;
            else demodulated(count*6-5)=0;
            end
            if (imag_after(count) > 0) demodulated(count*6-4)=1;
            else demodulated(count*6-4)=0;
            end
            if (abs(real_after(count)) > 4) demodulated(count*6-3)=1;
            else demodulated(count*6-3)=0;
            end
            if (abs(imag_after(count)) > 4) demodulated(count*6-2)=1;
            else demodulated(count*6-2)=0;
            end
            
            absolute_real = abs(real_after(count));
            absolute_imag = abs(imag_after(count));
            
            if or(and(absolute_real > 0,absolute_real < 2),and(absolute_real > 6,absolute_real < 8))
                demodulated(count*6-1)=1;
            else demodulated(count*6-1)=0;
            end
            if or(and(absolute_imag > 0,absolute_imag < 2),and(absolute_imag > 6,absolute_imag < 8))
                demodulated(count*6)=1;
            else demodulated(count*6)=0;
            end
        end
    end
end