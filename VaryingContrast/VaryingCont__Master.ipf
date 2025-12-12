#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// Procedure to call all functions for full analysis of varying contrast traces

Function VarCont_Full(roiMatName) 

string roiMatName // the name of the recording e.g. F1AZ2_S

// deconvolve
DeconvolveT2($roiMatName, 0, 0.06)
//
//// z-normalise the trace (subtract mean during baseline, divide by SD)
////z_norm_Trace(trace)
//
// Create matrices of response snippets for DF/F trace and deconvolved trace
wave trace_decon, trace, order
VarCont_Matrix()

// Get ave amp during transient, sustained and rebound portions of response (both DF/F and decon traces)
GetAmps()

// Calc the dark-light index (both DF/F and decon traces)
DarkLightIndex()

// Calc the dark-light index for Trans, Sust and Reb portions of the resp (DF/F and decon traces)

// Measure adaptation index from snips (both DF/F and decon traces)
AdaptationIndexCalc()

// Calculate where baseline sits within dynamic range from D1 means
wave RespMeans_Z, D_RespMeans_Z
VarCont_Baseline(RespMeans_Z,0)
VarCont_Baseline(D_RespMeans_Z,2)

// Measure time to half peak and calculate temporal jitter from DF/F and decon snips
VarCont_TemporalJitter()

//// Measure tau of adaptation with D2 snips
//wave RespSnips_D2, Time_trans_PeakXloc
//GetTau(RespSnips_D2, Time_trans_PeakXloc)
//
PlotData(roiMatName, 0)
PlotData(roiMatName, 2)
END
