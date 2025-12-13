#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function PeakRise_TemporalJitter()
wave PeakRise_xloc_PerStim_Thresh, StimPeakTimes
duplicate/o PeakRise_xloc_PerStim_Thresh, PeakRise_TimeToPeak
PeakRise_TimeToPeak-=StimPeakTimes
PeakRise_TimeToPeak*=1000

make/o/n=(1) PeakRise_TimeToPeak_mean
make/o/n=(1) PeakRise_TimeToPeak_SD
wavestats/q PeakRise_TimeToPeak
PeakRise_TimeToPeak_mean = v_avg
PeakRise_TimeToPeak_SD = v_sdev

end

Function Peak_TemporalJitter()
wave peak_xloc_perStim_Thresh, StimPeakTimes
duplicate/o peak_xloc_perStim_Thresh, Peak_TimeToPeak
Peak_TimeToPeak-=StimPeakTimes
Peak_TimeToPeak*=1000

make/o/n=(1) Peak_TimeToPeak_mean
make/o/n=(1) Peak_TimeToPeak_SD
wavestats/q Peak_TimeToPeak
Peak_TimeToPeak_mean = v_avg
Peak_TimeToPeak_SD = v_sdev

end 
