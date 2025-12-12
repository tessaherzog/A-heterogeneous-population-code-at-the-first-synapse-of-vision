#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// 2023.02.13
// Calling command for paired pulse analysis for 2 to 100 ISI conditions in psuedo-randomised order

Function PPAnal_2to100_Rand(recording, firststimtouse)
wave recording
variable firststimtouse

make/o/n=(1) FirstStim = firststimtouse

duplicate/o recording, trace
DeconvolveT2(trace,0,0.06)
MakeArrays_PP_Rand2to100(recording, firststimtouse)
TemplateCreator()
wave RespSnips_decon_FSTU
PeakFinder_Rand(RespSnips_decon_FSTU)
CalcPairedPulseRatio()

end
