#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// Mixed duration off-steps (5 to 100 ms) stimulus
// Pull the max response amplitude

Function PullPeakAmps_5to100(SelecTrace)
wave SelecTrace

// Detect and threshold responses
wave RespSnips
PullPeakAmpsXlocs(RespSnips)
wave SelecTrace
Thresholding(SelecTrace)
CheckOutlierResps()
PercMissedRespsPerCond()

// Calculate mean response amplitudes 
wave RespPeakAmps
CalcMeanPeakAmp(RespPeakAmps)

//Plot amplitude as a function of stim condition
wave RespPeakAmps_Ex_Thresh_Mean, RespPeakAmps_Ex_Thresh_SD, RespPeakAmps_Ex_Thresh_Var
DisplayRespAmpMean(RespPeakAmps_Ex_Thresh_Mean, RespPeakAmps_Ex_Thresh_SD)
PlotVarVsMean(RespPeakAmps_Ex_Thresh_Mean, RespPeakAmps_Ex_Thresh_Var)

end

//////////////////////////////////////////////////////
// Pull amplitude of peak for each response snippet into RespPeakAmps matrix
// Pull xLoc of peak into RespPeakxLocs matrix

Function PullPeakAmpsXlocs(w) // use RespSnips
wave w
variable nStimReps = dimsize(w,1)
variable nStimConds = dimsize(w,2)
variable i, j

variable transientstart = 60
variable transientend = 150

make/o/n=(1) WinStart = transientstart
make/o/n=(1) WinEnd = transientend

make/o/n = (nStimReps, nStimConds) RespPeakAmps
make/o/n = (nStimReps, nStimConds) RespPeakxLocs

for (i=0;i<nStimConds;i+=1)
	for (j=0;j<nStimReps;j+=1)
		duplicate/o/r=[transientstart,transientend][j][i] w, tempTrans
		Redimension/N=-1 temptrans
		SetScale/P y 0,1,"", tempTrans;DelayUpdate
		SetScale/P z 0,1,"", tempTrans
		wavestats/q tempTrans
		RespPeakAmps[j][i] = v_max
		RespPeakxLocs[j][i] = V_maxloc
		killwaves tempTrans
	endfor
endfor
RespPeakxLocs*=1000

duplicate/o RespPeakAmps, RespPeakAmps_Ex // duplicate and exlclude first X responses
duplicate/o RespPeakxLocs, RespPeakxLocs_Ex
wave stimTimesMat_Ex
for (i=0;i<nStimConds;i+=1)
	for (j=0;j<nStimReps;j+=1)
		if (numtype(stimTimesMat_Ex[i][j]) == 2)
			RespPeakAmps_Ex[j][i] = NaN
			RespPeakxLocs_Ex[j][i] = NaN
		endif
	endfor
endfor

end

Function Thresholding(SelecTrace) // threshold responses - if less than threshold = NaN
wave SelecTrace
wave RespPeakAmps, RespPeakxLocs, RespSnips
variable nStimReps = dimsize(RespPeakAmps,0)
variable nStimConds = dimsize(RespPeakAmps,1)
variable i, j

wave RespPeakAmps_Ex, RespPeakxLocs_Ex
duplicate/o RespPeakAmps_Ex, RespPeakAmps_Ex_Thresh
duplicate/o RespPeakxLocs_Ex, RespPeakxLocs_Ex_Thresh

duplicate/o/r=[3000,3500] SelecTrace, temp
wavestats/q temp
make/o/n=(1) Threshold = v_avg + V_sdev // set threshold as the mean + SD during bright light levels.
variable thresholdvar = Threshold[0]

for (i=0;i<nStimConds;i+=1) // NaN responses below threshold
	for (j=0;j<nStimReps;j+=1)
		if (RespPeakAmps_Ex[j][i] < thresholdvar)
			RespPeakAmps_Ex_Thresh[j][i] = NaN
			RespPeakxLocs_Ex_Thresh[j][i] = NaN
		endif
	endfor
endfor	

end

Function CheckOutlierResps() // user input required to check the outlier responses at edge of detection window

wave RespPeakAmps, RespPeakxLocs, RespPeakAmps_Ex_Thresh, RespPeakxLocs_Ex_Thresh, RespSnips
variable nStimReps = dimsize(RespPeakAmps_Ex_Thresh,0)
variable nStimConds = dimsize(RespPeakAmps_Ex_Thresh,1)
variable i, j
wave WinStart, WinEnd, Threshold

for (i=0;i<nStimConds;i+=1) // display responses which have an xloc at the edge of the peak detection window - i.e. likely to be incorrect
	for(j=0;j<nStimReps;j+=1)
		if (numtype(RespPeakAmps_Ex_Thresh[j][i]) == 0) // if there is a detected response
			if (RespPeakxLocs_Ex_Thresh[j][i] == WinStart[0] || RespPeakxLocs_Ex_Thresh[j][i] == WinEnd[0]) // and the peak is at the edge of the detection window
				display/k=1/N=PeakCheck RespSnips[][j][i]
				ModifyGraph axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1}
				SetAxis/A/N=1 left
				ModifyGraph rgb=(0,0,0)
		
				SetDrawEnv xcoord= bottom,ycoord= left,arrow= 1;DelayUpdate // draw arrow to detected peak
				DrawLine RespPeakxLocs[j][i]/1000,RespPeakAmps[j][i]+0.2,RespPeakxLocs[j][i]/1000,RespPeakAmps[j][i]
				
				SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (65535,0,0),dash= 1;DelayUpdate // draw noise threshold line
				DrawLine 0,Threshold[0],0.4,Threshold[0]
				SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (0,0,65535),dash= 1;DelayUpdate // draw time window for peak detection
				DrawLine WinStart[0]/1000,-1,WinStart[0]/1000,1
				SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (0,0,65535),dash= 1;DelayUpdate
				DrawLine WinEnd[0]/1000,-1,WinEnd[0]/1000,1	
			
				// user input here to place cursor at true response peak.
				DrawText 0.0831265508684863,0.0824742268041237,"Place cursor at true peak"
				ShowInfo
			
				variable autoAbortSecs = 0
				if (UserCursorAdjust("PeakCheck",autoAbortSecs)!=0)
					return -1
				endif
				variable TrueAmp
				variable TrueXLoc
   				TrueXLoc = pcsr(A)
   				TrueAmp = vcsr(A)
   				if (TrueAmp > threshold[0]) // correct peak amp and xLoc values
   					RespPeakxLocs_Ex_Thresh[j][i] = TrueXLoc
   					RespPeakAmps_Ex_Thresh[j][i] = TrueAmp
   					print "Corr. amp = " + num2str(TrueAmp) + " and corr. time pnt = " + num2str(TrueXLoc)
				endif
				if (TrueAmp < threshold[0]) // if correct peak is below threshold, NaN values.
   					RespPeakxLocs_Ex_Thresh[j][i] = NaN
   					RespPeakAmps_Ex_Thresh[j][i] = NaN
   					print "Updated as missed response"
				endif
				killwindow PeakCheck
			endif
		endif
	endfor
endfor

End

//
// Calculate the percentage of missed responses per condition

Function PercMissedRespsPerCond()

// loop over array to find number of responses included in analysis
wave RespPeakAmps, RespPeakAmps_Ex, RespPeakAmps_Ex_Thresh
variable i, j
variable nStimIts = dimsize(RespPeakAmps,0)
variable nStimConds = dimsize(RespPeakAmps,1)

make/o/n=(1) nStim = 0
make/o/n=(1) nStim_Ex_Strt = 0
make/o/n=(1) nStim_Ex_Strt_Thresh = 0

nStim = nStimIts * nStimConds
for (i=0;i<nStimConds;i+=1)
	for (j=0;j<nStimIts;j+=1)
		if (numtype(RespPeakAmps_Ex[j][i]) == 2)
			nStim_Ex_Strt+=1
		endif
		if (numtype(RespPeakAmps_Ex_Thresh[j][i]) == 2)
			nStim_Ex_Strt_Thresh+=1
		endif
	endfor
endfor
			
make/o/n=(1) nStim_Ex_Strt_Perc = (nStim_Ex_Strt/nStim)*100
make/o/n=(1) nStim_Ex_Strt_Thresh_Perc = ((nStim_Ex_Strt_Thresh-nStim_Ex_Strt)/(nStim-nStim_Ex_Strt))*100

print num2str(nStim_Ex_Strt[0]) + " of 275 responses excluded due to response adaptation (" + num2str(nStim_Ex_Strt_Perc[0]) + "%)"
print num2str(nStim_Ex_Strt_Thresh[0]-nStim_Ex_Strt[0]) + " of " + num2str(nStim[0]-nStim_Ex_Strt[0]) + " responses additionally excluded due to thresholding and peak correction (" + num2str(nStim_Ex_Strt_Thresh_Perc[0]) + "%)"

end


//////////////////////////////////////////////////////
// Calculate mean and variance of peak amplitude for each response condition

Function CalcMeanPeakAmp(RespPeakAmps)
wave RespPeakAmps

variable nStimConds = dimsize(RespPeakAmps,1)
make/o/n=(nStimConds) RespPeakAmps_Mean
make/o/n=(nStimConds) RespPeakAmps_SD
make/o/n=(nStimConds) RespPeakAmps_var

variable i
for (i=0;i<nStimConds;i+=1)
	duplicate/o/r=[][i] RespPeakAmps, tempAmps
	wavestats/q tempAmps
	RespPeakAmps_Mean[i] = v_avg
	RespPeakAmps_SD[i] = v_sdev
	RespPeakAmps_var[i] = v_sdev^2
endfor

wave RespPeakAmps_Ex
make/o/n=(nStimConds) RespPeakAmps_Ex_Mean
make/o/n=(nStimConds) RespPeakAmps_Ex_SD
make/o/n=(nStimConds) RespPeakAmps_Ex_var

for (i=0;i<nStimConds;i+=1) // get mean and SD of responses (exlcuding first X)
	duplicate/o/r=[][i] RespPeakAmps_Ex, tempAmps
	wavestats/q tempAmps
	RespPeakAmps_Ex_Mean[i] = v_avg
	RespPeakAmps_Ex_SD[i] = v_sdev
	RespPeakAmps_Ex_var[i] = v_sdev^2
endfor

wave RespPeakAmps_Ex_Thresh
make/o/n=(nStimConds) RespPeakAmps_Ex_Thresh_Mean
make/o/n=(nStimConds) RespPeakAmps_Ex_Thresh_SD
make/o/n=(nStimConds) RespPeakAmps_Ex_Thresh_var

for (i=0;i<nStimConds;i+=1) // get mean and SD of responses (exlcuding first X and thresholded)
	duplicate/o/r=[][i] RespPeakAmps_Ex_Thresh, tempAmps
	wavestats/q tempAmps
	RespPeakAmps_Ex_Thresh_Mean[i] = v_avg
	RespPeakAmps_Ex_Thresh_SD[i] = v_sdev
	RespPeakAmps_Ex_Thresh_var[i] = v_sdev^2
endfor


end

//////////////////////////////////////////////////////
// Calculate the mean for the nomalised peak amplitude data

Function CalcMeanPeakAmp_nrm(RespPeakAmps)
wave RespPeakAmps
duplicate/o RespPeakAmps, RespPeakAmps_nrm
wavestats/q RespPeakAmps
RespPeakAmps_nrm/=v_max

variable nStimConds = dimsize(RespPeakAmps,1)
make/o/n=(nStimConds) RespPeakAmps_nrm_Mean
make/o/n=(nStimConds) RespPeakAmps_nrm_SD
make/o/n=(nStimConds) RespPeakAmps_nrm_var

variable i
for (i=0;i<nStimConds;i+=1)
	duplicate/o/r=[][i] RespPeakAmps_nrm, tempAmps
	wavestats/q tempAmps
	RespPeakAmps_nrm_Mean[i] = v_avg
	RespPeakAmps_nrm_SD[i] = v_sdev
	RespPeakAmps_nrm_var[i] = v_sdev^2
endfor

end

//////////////////////////////////////////////////////
// Plot response amplitude as a function of off step duration

Function DisplayRespAmpMean(MeanWave, SDwave)
wave MeanWave, SDwave
wave StimConds

string MeanWaveName = nameofwave(MeanWave)
string SDWaveName = nameofwave(SDwave)

Display/k=1 $MeanWaveName vs stimConds
ModifyGraph mode=4,marker=19,msize=1
Modifygraph RGB=(0,0,0)
ErrorBars $MeanWaveName Y,wave=($SDWaveName, $SDWaveName)

SetAxis/A/N=1 left;DelayUpdate
SetAxis bottom 0,*;DelayUpdate 
ModifyGraph zero(left)=2,lblMargin=5,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1};DelayUpdate
Label left "Response amplitude (F’ s-1)";DelayUpdate
Label bottom "Off-step duration (ms)"

// Add threshold level line
wave threshold
SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (65535,0,0),dash= 1;DelayUpdate
DrawLine 0,threshold[0],100,threshold[0]

// fit the function with a sigmoid
K0 = 0;
CurveFit/X=1/H="1000"/TBOX=768 Sigmoid $MeanWaveName /X=StimConds /D
string FitWaveName = "fit_" + nameofwave(MeanWave)
string FitWaveName_Nrm = "fit_" + nameofwave(MeanWave) + "_nrm"
duplicate/o $FitWaveName, nrmfit
variable fitmax = wavemax($FitWaveName)
nrmfit/=fitmax
duplicate/o nrmfit, $FitWaveName_Nrm
killwaves nrmfit

wave W_coef
duplicate/o W_coef, W_coef_sigmoidfit

make/o/n=(1) fit_SigmoidSlope
fit_SigmoidSlope[0] = W_coef_sigmoidfit[1]/(4*W_coef_sigmoidfit[3])
print fit_SigmoidSlope

end

// Plot variance in response amplitude as a function of off step duration
Function DisplayRespAmpVariance()
wave RespPeakAmps_Var, StimConds

Display/k=1 RespPeakAmps_Var vs stimConds
Modifygraph RGB=(0,0,0)
SetAxis/A/N=1 left;DelayUpdate
SetAxis bottom 0,*;DelayUpdate
ModifyGraph zero(left)=2,lblMargin=5,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1};DelayUpdate
Label left "Variance in response peak amplitude";DelayUpdate
Label bottom "Off-step duration (ms)"

end

// plot variance in response amplitude vs mean response amplitude
Function PlotVarVsMean(MeanAmpWave, VarAmpWave)
wave MeanAmpWave, VarAmpWave

variable MeanMax = wavemax(MeanAmpWave)
variable VarMax = wavemax(VarAmpWave)
variable AxesMax
if (MeanMax > VarMax)
	AxesMax = ceil(MeanMax)
endif
if (VarMax > MeanMax)
	AxesMax = Ceil(VarMax)
endif

display/k=1 VarAmpWave vs MeanAmpWave
SetAxis left 0,AxesMax;DelayUpdate
SetAxis bottom 0,AxesMax
ModifyGraph lblMargin=5,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1};DelayUpdate
Label left "Variance in amplitude";DelayUpdate
Label bottom "Mean amplitude (F’ s-1)"
ModifyGraph mode=2,lsize=3,rgb=(0,0,0)
SetDrawEnv xcoord= bottom,ycoord= left,dash= 1;DelayUpdate
DrawLine 0,0,AxesMax,AxesMax
ModifyGraph width=141,height=141
end
