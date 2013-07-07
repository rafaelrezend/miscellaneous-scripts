% This function retun the Simbol Error Rate percentage
function out = ser(send, received)

    counter=0;	% Count the number of wrong simbols
    l=length(send);
    for x=1:l
        if(abs( (received(x))-(send(x))) >1)
            counter=counter+1;
        end;
    end;
        
        % Return the percentage of Symbol Error
    out = 100*counter/l;
    
end

