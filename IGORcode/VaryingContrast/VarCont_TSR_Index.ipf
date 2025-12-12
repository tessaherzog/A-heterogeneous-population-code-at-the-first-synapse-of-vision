#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// FOR RED CONES ONLY
// 1) Use area under the curve for each response snippet.
// 2) Plot mean AUC (+/- SD) as a function of contrast step.
// 3) Calculate DLi (dark-light index) of synapse. 

Function TSRIndex()

// add zero crossing
wave AmpsTrans_mean, AmpsTrans_SD, stimconds, D_AmpsTrans_mean, D_AmpsTrans_SD
Add0Crossing(AmpsTrans_mean, AmpsTrans_SD, stimconds)
Add0Crossing(D_AmpsTrans_mean, D_AmpsTrans_SD, stimconds)

wave AmpsSust_mean, AmpsSust_SD, stimconds, D_AmpsSust_mean, D_AmpsSust_SD
Add0Crossing(AmpsSust_mean, AmpsSust_SD, stimconds)
Add0Crossing(D_AmpsSust_mean, D_AmpsSust_SD, stimconds)

wave AmpsReb_mean, AmpsReb_SD, stimconds, D_AmpsReb_mean, D_AmpsReb_SD
Add0Crossing(AmpsReb_mean, AmpsReb_SD, stimconds)
Add0Crossing(D_AmpsReb_mean, D_AmpsReb_SD, stimconds)

// Calculate transient index
wave AmpsTrans_mean_0X, D_AmpsTrans_mean_0X
calculateTi(AmpsTrans_mean_0X, 0)
calculateTi(D_AmpsTrans_mean_0X, 2)

// Calculate sustained index
wave AmpsSust_mean_0X, D_AmpsSust_mean_0X
calculateSi(AmpsSust_mean_0X, 0)
calculateSi(D_AmpsSust_mean_0X, 2)

// Calculate rebound index
wave AmpsReb_mean_0X, D_AmpsReb_mean_0X
calculateRi(AmpsReb_mean_0X, 0)
calculateRi(D_AmpsReb_mean_0X, 2)

end

///////////////////////////////////////////////////////////////////////////////////////////////
// Add a 0 value at 0% contrast so the plot crosses zero.

Function Add0Crossing(meanwave, SDwave, stimwave) // use Add0X(DLi_respAUC_mean_D1, DLi_respAUC_SD_D1, stimconds)

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

Function calculateTi(MeanAUC, tracetype) // use calculateDLi(DLi_respAUC_mean_0X)

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
make/o/n=(1) TransI_value
TransI_value = (PosRespAUC-NegRespAUC)/(PosRespAUC+NegRespAUC)

killwaves NegRespAUC, PosRespAUC
KillWaves  Mean_neg,Mean_neg_L,Mean_pos,Mean_pos_L

if (tracetype == 0) // rename according to trace type
	duplicate/o TransI_value, AmpsTrans_Ti
	killwaves TransI_value
endif

if (tracetype == 2)
	duplicate/o TransI_value, D_AmpsTrans_Ti
	killwaves TransI_value
endif

end

////////////////////////////////////////////////////////////////////

Function calculateSi(MeanAUC, tracetype)

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
make/o/n=(1) SustI_value
SustI_value = (PosRespAUC-NegRespAUC)/(PosRespAUC+NegRespAUC)

killwaves NegRespAUC, PosRespAUC
KillWaves  Mean_neg,Mean_neg_L,Mean_pos,Mean_pos_L

if (tracetype == 0) // rename according to trace type
	duplicate/o SustI_value, AmpsSust_Si
	killwaves SustI_value
endif

if (tracetype == 2)
	duplicate/o SustI_value, D_AmpsSust_Si
	killwaves SustI_value
endif

end

////////////////////////////////////////////////////////////////////

Function calculateRi(MeanAUC, tracetype)

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

if (NegRespAUC[0]>0) // Reb resp to -ve cont. are -ve. 
	NegRespAUC[0]=0 // if they go above zero, make them = 0
else
	NegRespAUC*=-1 // Must convert to positive to calculate the index. 
endif

if (PosRespAUC[0]<0) // Reb resp to +ve cont. are +ve
	PosRespAUC[0]=0 // if they go below zero, make them = 0
endif

//Calculate DLi as (a-b)/(a+b)
make/o/n=(1) RebI_value
RebI_value = (PosRespAUC-NegRespAUC)/(PosRespAUC+NegRespAUC)

killwaves NegRespAUC, PosRespAUC
KillWaves  Mean_neg,Mean_neg_L,Mean_pos,Mean_pos_L

if (tracetype == 0) // rename according to trace type
	duplicate/o RebI_value, AmpsReb_Ri
	killwaves RebI_value
endif

if (tracetype == 2)
	duplicate/o RebI_value, D_AmpsReb_Ri
	killwaves RebI_value
endif

end

////////////////////////////////////////////////////////////////////
// display contrast-response function +/- SD
//Function displayContResp(meanwave, SDwave, tracetype)
//wave meanwave, SDwave
//variable tracetype
//wave stimConds_0X, DLiValue, D_DLiValue
//
//string meanwavename = nameofwave(meanwave)
//string SDwavename = nameofwave(SDwave)
//
//display/k=1 $meanwavename vs stimConds_0X
//SetAxis/A/N=1 left
//ModifyGraph rgb=(0,0,0);DelayUpdate
//ModifyGraph mode=7,usePlusRGB=1,hbFill=5,plusRGB=(0,0,0)
//ErrorBars $meanwavename Y,wave=($SDwavename,$SDwavename)
//ModifyGraph zero=3,lblMargin=5,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1};DelayUpdate
//if (tracetype == 0)
//	label left "Total glutamate release (DF/F/s)";DelayUpdate
//	Label bottom "Contrast step from mean light level (%)"
//	DrawText 0.589498806682578,0.0981308411214953,"DLi: " + num2str(DLiValue[0])
//	ModifyGraph width=141.732,height=141.732
//endif
//
//if (tracetype == 2)
//	label left "Total glutamate release (F's-1/s)";DelayUpdate
//	Label bottom "Contrast step from mean light level (%)"
//	DrawText 0.589498806682578,0.0981308411214953,"Decon DLi: " + num2str(D_DLiValue[0])
//	ModifyGraph width=141.732,height=141.732
//endif
//
//end
