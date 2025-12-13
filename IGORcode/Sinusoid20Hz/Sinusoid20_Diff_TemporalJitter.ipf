#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function Diff_TemporalJitter()
wave DiffTrace_Peak_xLoc_Perstim, StimPeakTimes
duplicate/o DiffTrace_Peak_xLoc_Perstim, DiffTrace_TimeToPeak
DiffTrace_TimeToPeak-=StimPeakTimes
DiffTrace_TimeToPeak*=1000

make/o/n=(1) DiffTrace_TimeToPeak_mean
make/o/n=(1) DiffTrace_TimeToPeak_SD
wavestats/q DiffTrace_TimeToPeak
DiffTrace_TimeToPeak_mean = v_avg
DiffTrace_TimeToPeak_SD = v_sdev

end
