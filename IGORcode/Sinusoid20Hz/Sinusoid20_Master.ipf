#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// Master procedure for analysis of recordings to 20 Hz sinusoid

Function Sinusoid20Hz_FullAnal(w) // use recording
wave w

// deconvolve recording
DeconvolveT2(w, 0, 0.06)

// Cut trace into response snipppets 
wave trace_decon
Sin20Hz_MakeArrays(trace_decon)

// Differentiate trace and detect peaks
PeakAnal_20Hz(trace_decon)

// Organise detected peaks of differential into stimulus periods
PeaksInStim()
wave DiffTrace_Peak_xLoc_stim 
RespRise_OrgPerStim(DiffTrace_Peak_xLoc_stim)

// Get the amplitude of the differential peak on the glutamate trace (will be the peak rise on the trace)
GetRiseAmp(trace_decon)

// Find the peak in the trace (based on peak found in differential)
DetectTruePeak(trace_decon)

// Threshold peaks in trace based on mean + SD during "grey" light
ThresholdPeaks(trace_decon)

// Calculate percentage of stimulus phases that elicit a response
wave peak_Amp_perStim_Thresh
FractionOfResponses(peak_Amp_perStim_Thresh)

// Calculate the temporal jitter of peak on diff. trace (a.k.a the peak rise on the decon trace)
Diff_TemporalJitter() // calculate temporal jitter of differential peak.

// Calculate temporal jitter of time to peak on trace
PeakRise_TemporalJitter()
Peak_TemporalJitter()

END