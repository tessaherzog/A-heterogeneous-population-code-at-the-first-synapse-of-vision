#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//Create a fit of a response to use as template.
//Final response in 100 ms ISI condition is fitted to create the template. 
//The template is used to calculate the "true" amplitude of the second peak in paired pulse suppression recordings.
// Input: recording wave

Function TemplateCreator()
SnipFinalResp()
FitFinalResp()
end

///////////////////////////////////////////////////////////////////////////////////////////////////

Function SnipFinalResp()
wave RespSnips_decon
variable nPnts = dimsize(RespSnips_decon, 0)
variable nStimReps = dimsize(RespSnips_decon, 1)
variable nStimConds = dimsize(RespSnips_decon, 2)
// duplicate the second response to the final 100 ms ISI condition. 
// cut at 140 as this is 50 ms before the onset of the second pulse, meaning the fit will align with the onset of the first pulse in RespSnips
duplicate/o/r=[140, 480][nStimReps-1][nStimConds-1] RespSnips_decon, Final100msResp
Redimension/N=-1 Final100msResp
SetScale/P x 0.0,0.001,"", Final100msResp //snip already zeroed as taken from zeroed matrix
Final100msResp[0,30]=0 // make first 30 points = zero so they don't interfer with peak finding.

end

//////////////////////////////////////////////////////////////////////////////////////////////////
Function FitFinalResp()
wave Final100msResp

variable maxamp //get max amplitude and xloc for curve fitting
variable maxampxloc
wavestats/q Final100msResp
maxamp = v_max
maxampxloc = V_maxloc
maxampxloc*=1000 //to convert to points

variable final50ave //get average of baseline after response for curve fitting 
duplicate/o/r=[340-50,340] Final100msResp, final50
wavestats/q final50
final50ave = v_avg
killwaves final50

display/k=1 Final100msResp
ModifyGraph rgb=(0,0,0)

// choose correct fit type, according to trace, e.g....
//K0 = final50ave;
//CurveFit/H="10000" dblexp_XOffset Final100msResp[maxampxloc,maxampxloc+199] /D
K0 = final50ave;K1 = maxamp;
CurveFit/H="1100"/TBOX=768 HillEquation Final100msResp[maxampxloc,maxampxloc+199] /D
SetAxis/A/N=1 left

wave fit_Final100msResp
variable fit_maxamp
wavestats/q fit_Final100msResp
fit_maxamp = v_max

duplicate/o fit_Final100msResp, fit_FinalResp_nrm
fit_FinalResp_nrm/=fit_maxamp
end
