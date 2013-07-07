function corr = correlator(signal,preamble)

    preamble = fliplr(preamble);
    c = conv (preamble, signal);
    s2 = abs(signal).*abs(signal);
    d = conv (s2, ones(1,length(preamble)));

    corr = (abs(c).*abs(c))./d;

end