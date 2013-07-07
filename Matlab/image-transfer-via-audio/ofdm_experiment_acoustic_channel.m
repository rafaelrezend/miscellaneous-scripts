%USER INPUT
N = input('Enter the size of frame: ');
Nl = input('Enter the size of packet: ');
l = input('Enter size of cycle prefix: ');
S = input('Enter the size of QAM constelation [4,16,64]: ');
Nt = input('Enter the number of frames of the training packet: ');
%END OF USER INPUT


%BEGIN OF SENDER
%============================================================
sender_training = generate_training(Nt*(N/2-1)*log2(S));
sender_training = qa_mod(sender_training, S);
sender_training = reshape(sender_training,(N/2-1),Nt);
sender_training = [zeros(1,Nt); sender_training; zeros(1,Nt); flipdim(conj(sender_training),1)];

%Sequence from image
[data image_H image_W]=load_image('./Lenna.jpg');

%rounding data size according to bits per symbol
data_size = length(data);
if (data_size < Nl*N*log2(S))
    error('Image is too small for the size of packet.');
end
data_size = log2(S)*floor(data_size/log2(S));
data = data(1:data_size);

%generate the complex vector from data (QAM)
data_complex = qa_mod(data,S);

%rounding data size according to symbols per frame (N/2 -1) and frames per
%packet (Nl)
data_size = length(data_complex);
amount_packets = floor(data_size/((N/2-1)*Nl));
data_size = amount_packets*Nl*(N/2-1);

%obtaining the rounded data_complex
data_complex = data_complex(1:data_size);

sender_data_qa = data_complex; %stored for SER

%Max loss of data ((N/2-1)*Nl)-1 symbols

%generate packet containing zero vectors and conjugated
data_packet = reshape(data_complex,(N/2-1),length(data_complex)/(N/2-1));
data_packet = [zeros(1,Nl*amount_packets); data_packet; zeros(1,Nl*amount_packets); flipdim(conj(data_packet),1)];

%adding training to data
packet = [];
for i = 1:amount_packets
    packet = [packet sender_training data_packet(:,(((i-1)*Nl)+1):(i*Nl))];
end

%modulating packet (OFDM)
serial_packet = ofdm_mod(packet, l);

%adding delay before and after the signal to simulate a runtime scenario
%(mute channel with transient data)
serial_packet = [zeros(1,1000) serial_packet zeros(1,1000)];

%sampling frequency
fs = 16000;

t = 0:1/fs:(length(serial_packet))/fs;
simin = [t(1:length(t)-1)' serial_packet'];

%============================================================
%END OF SENDER

%BEGIN OF CHANNEL
%============================================================
%at this point, play the audio_io file to record the output simout
duration = length(serial_packet)/fs + 1;
sim('audio_io');
%test with channel provided by professor;
% simout = acoustic_channel_tv(simin(:,2)');
%============================================================
%END OF CHANNEL

%BEGIN OF RECEIVER
%============================================================
%demodulating packet
received_packet = simout';
%removing the DC component
received_packet = received_packet - mean(received_packet);

%generating the training to perform the cross-correlation on signal
receiver_training = generate_training(Nt*(N/2-1)*log2(S));
receiver_training = qa_mod(receiver_training, S);
receiver_training = reshape(receiver_training,(N/2-1),Nt);
receiver_training_composed = [zeros(1,Nt); receiver_training; zeros(1,Nt); flipdim(conj(receiver_training),1)];
receiver_training_ofdm = ofdm_mod(receiver_training_composed, l);

%getting the cross-correlator
cross = correlator(received_packet, receiver_training_ofdm);
threshold = max(cross)/4.8;
cross = max(cross, threshold); %65 is the threshold
cross = cross - threshold;

fixed_received_data = [];
index_peak = 1;

while index_peak < length(received_packet)
    
    %getting the highest peak that represents the end of training
    pointer = round(index_peak+Nt*(N+l)/5);
    offset = find(cross(pointer:end),1) - 1; %next peak
    if (isempty(offset)) %no more peaks on cross-correlation
        break;
    end
    pointer = pointer + offset;
    [var, offset] = max(cross(pointer:round(pointer+Nt*(N+l)/3))); %check higher peak closer
    pointer = pointer + offset - 1;
    index_peak = pointer - 10; %-10 is a practical correction to set the beginning
    
    %splitting training and data
    received_training = received_packet(:,index_peak+1-Nt*(N+l):index_peak);
    received_data = received_packet(:,index_peak+1:(index_peak+Nl*(N+l)));
    
    %demodulating signals on OFDM
    received_data_demod = ofdm_demod(received_data, N, l);
    received_training_demod = ofdm_demod(received_training, N, l);
    
    %removing zeros and conjugated
    received_data_demod = received_data_demod(2:N/2,:);
    received_training_demod = received_training_demod(2:N/2,:);
        
    %obtaining the frequency response
    H = received_training_demod./receiver_training;
    H = mean(H,2);    
    H = repmat(H,1,Nl);
    %applying the equalization on received data
    fixed_received_data = [fixed_received_data received_data_demod./H];
        
end

%serializing the fixed received data
fixed_data_serial = reshape(fixed_received_data, 1, size(fixed_received_data,1)*size(fixed_received_data,2));

received_data_qa = fixed_data_serial; %stored for SER

%demodulating from complex to binary sequence
fixed_data_serial = qa_demod(fixed_data_serial,S);

%============================================================
%END OF RECEIVER

%CHECKING THE IMAGE AND RESULTS
%checking the errors
ber_result = ber(data(1:length(fixed_data_serial)), fixed_data_serial);
ser_result = ser(sender_data_qa, received_data_qa);

Theoretical_total_time = (l+N)*(Nl+Nt)*floor((floor(length(data)/(log2(S)*(N/2-1))))/Nl)/fs; %seconds
bit_rate = length(data)/Theoretical_total_time; %bit/s

fixed_data_serial = [fixed_data_serial zeros(1, image_H*image_W*8 - length(fixed_data_serial))];
view_image(fixed_data_serial, image_H, image_W);