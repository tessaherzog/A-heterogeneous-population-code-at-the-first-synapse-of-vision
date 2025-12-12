#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// FOR RED CONES ONLY
// 1) Use area under the curve for each response snippet.
// 2) Plot mean AUC (+/- SD) as a function of contrast step.
// 3) Calculate DLi (dark-light index) of synapse. 

Function DarkLightIndex()

wave RespSnips_Z, D_RespSnips_Z // get AUC of each response snippet
PullRespAUC(RespSnips_Z, 500, 0)
PullRespAUC(D_RespSnips_Z, 500,2)

wave DLi_RespAUC, D_DLi_RespAUC // get average AUC of responses
aveRespAUC(DLi_RespAUC, 0)
aveRespAUC(D_DLi_RespAUC, 2)

wave DLi_RespAUC_mean, DLi_RespAUC_SD, D_DLi_RespAUC_mean, D_DLi_RespAUC_SD, stimconds // add zero crossing
Add0X(DLi_RespAUC_mean, DLi_RespAUC_SD, stimconds)
Add0X(D_DLi_RespAUC_mean, D_DLi_RespAUC_SD, stimconds)

wave DLi_RespAUC_mean_0X, D_DLi_RespAUC_mean_0X
calculateDLi(DLi_RespAUC_mean_0X, 0)
calculateDLi(D_DLi_RespAUC_mean_0X, 2)

wave DLi_RespAUC_SD_0X, D_DLi_RespAUC_SD_0X
//displayContResp(DLi_RespAUC_mean_0X, DLi_RespAUC_SD_0X, 0)
//displayContResp(D_DLi_RespAUC_mean_0X, D_DLi_RespAUC_SD_0X, 2)
end

////////////////////////////////////////////////////////////////////
// Pull the area under the curve for each response snippet and store in array called DLi_respAUC.
Function PullRespAUC(RespSnipsMat, respwin, tracetype) // use PullRespAUC(RespSnips_D1, 500)
wave RespSnipsMat
variable respwin
variable tracetype

variable i, j
variable sniplen = dimsize(RespSnipsMat,0)
variable nReps = dimSize(RespSnipsMat,1)
variable nStimConds = dimsize(RespSnipsMat,2)

make/o/n=(nReps,nStimConds), DLi_responseAUC // make an array to store the AUC values, each stim condition per column. 

for (i=0;i<nStimConds;i+=1)
	for (j=0;j<nReps;j+=1)
		duplicate/o/r=[500,500+respwin][j][i] RespSnipsMat, tempsnip
		Redimension/N=-1 tempsnip
		DLi_responseAUC[j][i] = area(tempsnip)
	endfor
endfor

killwaves tempsnip

if (tracetype == 0) // rename according to trace type
	duplicate/o DLi_responseAUC, DLi_RespAUC
	killwaves DLi_responseAUC
endif

if (tracetype == 2)
	duplicate/o DLi_responseAUC, D_DLi_RespAUC
	killwaves DLi_responseAUC
endif

end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// Calculate mean and SD of the AUC for each stim condition

Function aveRespAUC(w, tracetype) // use aveRespAUC(DLi_respAUC, 0)
wave w
variable tracetype
variable nStimConds = dimsize(w,1)
variable i

make/o/n=(nStimConds) DLi_responseAUC_mean
make/o/n=(nStimConds) DLi_responseAUC_SD

for (i=0;i<nStimConds;i+=1)
	duplicate/o/r=[][i] w, tempAUC
	wavestats/q tempAUC
	DLi_responseAUC_mean[i] = v_avg
	DLi_responseAUC_SD[i] = v_sdev
	killwaves tempAUC
endfor

if (tracetype == 0) // rename according to trace type
	duplicate/o DLi_responseAUC_mean, DLi_RespAUC_mean
	duplicate/o DLi_responseAUC_SD, DLi_RespAUC_SD
	killwaves DLi_responseAUC_mean, DLi_responseAUC_SD
endif

if (tracetype == 2)
	duplicate/o DLi_responseAUC_mean, D_DLi_RespAUC_mean
	duplicate/o DLi_responseAUC_SD, D_DLi_RespAUC_SD
	killwaves DLi_responseAUC_mean, DLi_responseAUC_SD
endif

end

///////////////////////////////////////////////////////////////////////////////////////////////
// Add a 0 value at 0% contrast so the plot crosses zero.

Function Add0X(meanwave, SDwave, stimwave) // use Add0X(DLi_respAUC_mean_D1, DLi_respAUC_SD_D1, stimconds)

wave meanwave, SDwave, stimwave

duplicate/o meanwave, meanwave_0X
InsertPoints 5,1, meanwave_0X
string mean0Xwavename = nameofWave(meanwave) + "_0X"
duplicate/o meanwave_0X, $mean0Xwavename

duplicate/o SDwave, SDwave_0X
InsertPoints 5,1, SDwave_0X
string SD0Xwavename = nameofWave(SDwave) + "_0X"
duplicate/o SDwave_0X, $SD0Xwavename

killwaves meanwave_0X, SDwave_0X

duplicate/o stimwave, StimConds_0X
InsertPoints 5,1, StimConds_0X

end

////////////////////////////////////////////////////////////////////

Function calculateDLi(MeanAUC, tracetype) // use calculateDLi(DLi_respAUC_mean_0X)

wave MeanAUC
variable tracetype
wave stimConds_0X

// separate normalised response curve for negative and positive contrast steps

duplicate/o/r=[0,5]MeanAUC, Mean_neg // duplicate out the repsonse curve for the neg contrast steps
duplicate/o/r=[5,10]MeanAUC, Mean_pos // duplicate out the repsonse curve for the pos contrast steps

duplicate/o/r=[0,5] stimConds_0X, stimConds_0X_Neg //duplicate out the negative contrast step conditions
duplicate/o/r=[5,10] stimConds_0X, stimConds_0X_Pos //duplicate out the positive contrast step conditions

// interpolate response curve sections, to get evenly spaced x values with respect to the stimulus conditions

Interpolate2/T=1/N=200/Y=Mean_neg_L stimConds_0X_Neg,Mean_neg;DelayUpdate // interpolate the response curve to make X points evently spaced
Interpolate2/T=1/N=200/Y=Mean_pos_L stimConds_0X_Pos,Mean_pos;DelayUpdate

killwaves stimConds_0X_Neg, stimConds_0X_Pos

//Pull AUC for the normalised pos and neg response curve sections

make/o/n=(1) NegRespAUC
make/o/n=(1) PosRespAUC

//AUC for response curve to negative contrasts
NegRespAUC= area(Mean_neg_L)

//AUC for response curve to positive contrasts.
//if respAUCmean_0X_nrm_pos_L is a +ve value, make it =0, else if it is a negative value, *=-1.
//this is because the a-b/a+b calculation can't work with negative values. 
// respAUCmean_0X_nrm_pos_L*=-1 //comment this out
PosRespAUC = area(Mean_pos_L)

// print PosRespAUC

if (PosRespAUC[0]>0) // if responses to positive contrast go above 0, zero them. 
	PosRespAUC[0]=0
else
	PosRespAUC*=-1 // responses to positive contrasts are negative. Must convert to positive to calculate the index. 
endif

//Calculate DLi as (a-b)/(a+b)
make/o/n=(1) DLiVal
DLiVal = (PosRespAUC-NegRespAUC)/(PosRespAUC+NegRespAUC)
print DLiVal

killwaves NegRespAUC, PosRespAUC
KillWaves  Mean_neg,Mean_neg_L,Mean_pos,Mean_pos_L

if (tracetype == 0) // rename according to trace type
	duplicate/o DLiVal, DLiValue
	killwaves DLiVal
endif

if (tracetype == 2)
	duplicate/o DLiVal, D_DLiValue
	killwaves DLiVal
endif

end

////////////////////////////////////////////////////////////////////
// display contrast-response function +/- SD
Function displayContResp(meanwave, SDwave, tracetype)
wave meanwave, SDwave
variable tracetype
wave stimConds_0X, DLiValue, D_DLiValue

string meanwavename = nameofwave(meanwave)
string SDwavename = nameofwave(SDwave)

display/k=1 $meanwavename vs stimConds_0X
SetAxis/A/N=1 left
ModifyGraph rgb=(0,0,0);DelayUpdate
ModifyGraph mode=7,usePlusRGB=1,hbFill=5,plusRGB=(0,0,0)
ErrorBars $meanwavename Y,wave=($SDwavename,$SDwavename)
ModifyGraph zero=3,lblMargin=5,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1};DelayUpdate
if (tracetype == 0)
	label left "Total glutamate release (DF/F/s)";DelayUpdate
	Label bottom "Contrast step from mean light level (%)"
	DrawText 0.589498806682578,0.0981308411214953,"DLi: " + num2str(DLiValue[0])
	ModifyGraph width=141.732,height=141.732
endif

if (tracetype == 2)
	label left "Total glutamate release (F's-1/s)";DelayUpdate
	Label bottom "Contrast step from mean light level (%)"
	DrawText 0.589498806682578,0.0981308411214953,"Decon DLi: " + num2str(D_DLiValue[0])
	ModifyGraph width=141.732,height=141.732
endif

end
