function signal = generateTone(toneFreq, samples, fs, amplitude)
    time = (0:samples-1) / fs;
    signal = amplitude * sin(2 * pi * toneFreq * time);
end
