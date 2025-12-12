#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// FOR RED CONES ONLY
// Pull the amplitude at the transient, sustained and rebound portion of the response. 

Function GetAmps() // tracetype 0 = DF/F, 2 = Decon2
wave RespSnips_Z, RespMeans_Z, D_RespSnips_Z, D_RespMeans_Z
DetectTransient(RespSnips_Z, RespMeans_Z, 0)
DetectTransient(D_RespSnips_Z, D_RespMeans_Z, 2)
DetectRebound(RespSnips_Z, RespMeans_Z, 0)
DetectRebound(D_RespSnips_Z, D_RespMeans_Z, 2)

wave RespSnips_z, D_RespSnips_z
Get_TSR_Amps(RespSnips_Z, RespMeans_Z, 0)
Get_TSR_Amps(D_RespSnips_Z, D_RespMeans_Z, 2)

wave AmpsTrans, AmpsSust, AmpsReb, D_AmpsTrans, D_AmpsSust, D_AmpsReb
AverageConds(AmpsTrans, AmpsSust, AmpsReb, 0)
AverageConds(D_AmpsTrans, D_AmpsSust, D_AmpsReb, 2)

wave AmpsTrans_mean, AmpsTrans_Var, AmpsSust_Mean, AmpsSust_Var, AmpsReb_Mean, AmpsReb_Var
wave D_AmpsTrans_Mean, D_AmpsTrans_Var, D_AmpsSust_Mean, D_AmpsSust_Var, D_AmpsReb_Mean, D_AmpsReb_Var
FanoFactor(AmpsTrans_mean, AmpsTrans_Var, AmpsSust_Mean, AmpsSust_Var, AmpsReb_Mean, AmpsReb_Var, 0)
FanoFactor(D_AmpsTrans_Mean, D_AmpsTrans_Var, D_AmpsSust_Mean, D_AmpsSust_Var, D_AmpsReb_Mean, D_AmpsReb_Var, 2)

//PlotDeconAmps(0)
//PlotDeconAmps(2)

END

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function DetectTransient(RespSnipMat, RespMeanMat, tracetype) // use RespSnips or RespSnips_D1
wave RespSnipMat, RespMeanMat
variable tracetype

// Get xloc of peak in mean resp to -100% C. to set window for transient detection to negative contrasts
duplicate/o/r=[500,700][0] RespMeanMat, temp
wavestats/q temp
variable transPeak_100Neg = V_maxloc*1000
print transPeak_100Neg
killwaves temp

// Get xloc of dip in mean resp to +100% C. to set window for transient detection to positive contrasts
duplicate/o/r=[500,700][9] RespMeanMat, temp
wavestats/q temp
variable transPeak_100Pos = V_minloc*1000
print transPeak_100Pos
killwaves temp

variable TransientWin = 50 // ms before and after peak to create window for transient peak detection
variable i, j
variable nReps = dimsize(RespSnipMat,1)
variable nConds = dimsize(RespSnipMat,2)

// Get the transient peak and xloc for negative contrasts
make/o/n=(nReps,nConds) Trans_Peak_xloc
make/o/n=(nReps,nConds) Trans_Peak_Amp

for (i=0;i<nConds/2;i+=1) // loop over -ve c conditions
	for(j=0;j<nReps;j+=1) //loop over repeats
		duplicate/o/r=[transPeak_100Neg-TransientWin, transPeak_100Neg+TransientWin][j][i] RespSnipMat, temptrans // slightly larger window for accurate peak detec.
		Redimension/N=-1 temptrans
		wavestats/q temptrans
		Trans_Peak_amp[j][i] = v_max
		Trans_Peak_xloc[j][i] = v_maxloc
		killwaves temptrans
	endfor
endfor

// Get the transient peak and xloc for positive contrasts
make/o/n=(nReps,nConds) Trans_Peak_xloc
make/o/n=(nReps,nConds) Trans_Peak_Amp

for (i=nConds/2;i<nConds;i+=1) // loop over +ve c conditions
	for(j=0;j<nReps;j+=1) //loop over repeats
		duplicate/o/r=[transPeak_100Pos-TransientWin, transPeak_100Pos+TransientWin][j][i] RespSnipMat, temptrans // slightly larger window for accurate peak detec.
		Redimension/N=-1 temptrans
		wavestats/q temptrans
		Trans_Peak_amp[j][i] = v_min
		Trans_Peak_xloc[j][i] = v_minloc
		killwaves temptrans
	endfor
endfor

if (tracetype == 0)
	duplicate/o Trans_Peak_amp, TransPeak_amp
	duplicate/o Trans_Peak_xloc, TransPeak_xloc
	killwaves Trans_Peak_amp, Trans_Peak_xloc
endif

if (tracetype == 2)
	duplicate/o Trans_Peak_amp, D_TransPeak_amp
	duplicate/o Trans_Peak_xloc, D_TransPeak_xloc
	killwaves Trans_Peak_amp, Trans_Peak_xloc
endif

end

////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function DetectRebound(RespSnipMat, RespMeanMat, tracetype) // use RespSnips or RespSnips_D1
wave RespSnipMat, RespMeanMat
variable tracetype

// Get xloc of peak in mean resp to -100% C. to set window for transient detection to negative contrasts
duplicate/o/r=[1100,1300][0] RespMeanMat, temp
wavestats/q temp
variable RebPeak_100Neg = V_minloc*1000
print RebPeak_100Neg
killwaves temp

// Get xloc of dip in mean resp to +100% C. to set window for transient detection to positive contrasts
duplicate/o/r=[1050,1150][9] RespMeanMat, temp
wavestats/q temp
variable RebPeak_100Pos = V_maxloc*1000
print RebPeak_100Pos
killwaves temp

variable ReboundWin = 50 // ms before and after peak to create window for transient peak detection
variable i, j
variable nReps = dimsize(RespSnipMat,1)
variable nConds = dimsize(RespSnipMat,2)

// Get the rebound peak and xloc for negative contrasts
make/o/n=(nReps,nConds) Reb_Peak_xloc
make/o/n=(nReps,nConds) Reb_Peak_Amp

for (i=0;i<nConds/2;i+=1) // loop over -ve c conditions
	for(j=0;j<nReps;j+=1) //loop over repeats
		duplicate/o/r=[RebPeak_100Neg-ReboundWin, RebPeak_100Neg+ReboundWin][j][i] RespSnipMat, tempReb
		Redimension/N=-1 tempReb
		wavestats/q tempReb
		Reb_Peak_amp[j][i] = v_min
		Reb_Peak_xloc[j][i] = v_minloc
		killwaves tempReb
	endfor
endfor

// Get the rebound peak and xloc for positive contrasts
make/o/n=(nReps,nConds) Reb_Peak_xloc
make/o/n=(nReps,nConds) Reb_Peak_Amp

for (i=nConds/2;i<nConds;i+=1) // loop over +ve c conditions
	for(j=0;j<nReps;j+=1) //loop over repeats
		duplicate/o/r=[RebPeak_100Pos-ReboundWin, rebPeak_100Pos+ReboundWin][j][i] RespSnipMat, tempReb // slightly larger window for accurate peak detec.
		Redimension/N=-1 tempReb
		wavestats/q tempReb
		Reb_Peak_amp[j][i] = v_max
		Reb_Peak_xloc[j][i] = v_maxloc
		killwaves tempReb
	endfor
endfor

if (tracetype == 0)
	duplicate/o Reb_Peak_amp, RebPeak_amp
	duplicate/o Reb_Peak_xloc, RebPeak_xloc
	killwaves Reb_Peak_amp, Reb_Peak_xloc
endif

if (tracetype == 2)
	duplicate/o Reb_Peak_amp, D_RebPeak_amp
	duplicate/o Reb_Peak_xloc, D_RebPeak_xloc
	killwaves Reb_Peak_amp, Reb_Peak_xloc
endif

end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Get the ave amp during transient, sustained and rebound portions of the response
Function Get_TSR_Amps(RespSnipMat, RespMeanMat, tracetype) // use RespSnips or RespSnips_D2

wave RespSnipMat, RespMeanMat
variable tracetype

//Get xloc of peak in mean resp to -100% c. to set window for transient detection to negative contrasts
duplicate/o/r=[500,600][0] RespMeanMat, temp
wavestats/q temp
variable transPeak_100Neg = V_maxloc*1000
print transPeak_100Neg
killwaves temp

// Get xloc of dip in mean resp to +100% C. to set window for transient detection to positive contrasts
duplicate/o/r=[500,600][9] RespMeanMat, temp
wavestats/q temp
variable transPeak_100Pos = V_minloc*1000
print transPeak_100Pos
killwaves temp

// set windows for each response portion
variable TransWinSize = 10
variable transientstart = transPeak_100Neg - TranswinSize
variable transientend = transPeak_100Neg + TranswinSize
variable sustainedstart = 800
variable sustainedend = 1000

if (tracetype == 0) // if using DF/F
	variable reboundstart = 1100
	variable reboundend = 1300
endif

if (tracetype == 2) // if using decon2 trace
	reboundstart = 1050
	reboundend = 1200
endif

// pull average amp during transient window
variable nReps = dimsize(RespSnipMat,1)
variable nConds = dimsize(RespSnipMat,2)
variable i, j
make/o/n=(nReps,nConds) AmpsTransient
for (i=0;i<nConds;i+=1) // loop over conditions
	for(j=0;j<nReps;j+=1) //loop over repeats
		duplicate/o/r=[transientstart, transientend][j][i] RespSnipMat, temptrans
		Redimension/N=-1 temptrans
		wavestats/q temptrans
		AmpsTransient[j][i] = v_avg
		killwaves temptrans
	endfor
endfor

// pull average amp during sustained window
make/o/n=(nReps,nConds) AmpsSustained
for (i=0;i<nConds;i+=1) // loop over conditions
	for(j=0;j<nReps;j+=1) //loop over repeats
	duplicate/o/r=[sustainedstart, sustainedend][j][i] RespSnipMat, tempSust
	Redimension/N=-1 tempSust
	wavestats/q tempSust
	AmpsSustained[j][i] = V_avg
	killwaves tempSust
	endfor
endfor

// pull average amp during rebound window 
make/o/n=(nReps, nConds) AmpsRebound
for (i=0;i<nConds;i+=1) // loop over negative contrast steps to pull peak
	for(j=0;j<nReps;j+=1) //loop over repeats
	duplicate/o/r=[reboundstart, reboundend][j][i] RespSnipMat, tempReb
	Redimension/N=-1 tempReb
	wavestats/q tempReb
	AmpsRebound[j][i] = V_avg
	killwaves tempReb
	endfor
endfor

if (tracetype == 0)
	duplicate/o AmpsTransient, AmpsTrans
	duplicate/o AmpsSustained, AmpsSust
	duplicate/o AmpsRebound, AmpsReb
	killwaves AmpsTransient, AmpsSustained, AmpsRebound
endif

if (tracetype == 2)
	duplicate/o AmpsTransient, D_AmpsTrans
	duplicate/o AmpsSustained, D_AmpsSust
	duplicate/o AmpsRebound, D_AmpsReb
	killwaves AmpsTransient, AmpsSustained, AmpsRebound
endif

end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Calculate mean and SD for transient, sustained and rebound responses in each stimulus condition

Function AverageConds(AmpsTransient, AmpsSustained, AmpsRebound, tracetype)

wave AmpsTransient, AmpsSustained, AmpsRebound
variable tracetype
variable i
variable nReps = dimsize(AmpsTransient,0)
variable nConds = dimsize(AmpsTransient,1)

make/o/n=(nConds) AmpsTransient_Mean, AmpsTransient_SD, AmpsTransient_Var
for (i=0;i<nConds;i+=1)
	duplicate/o/r=[][i] AmpsTransient, tempwave
	wavestats/q tempwave
	AmpsTransient_Mean[i] = v_avg
	AmpsTransient_SD[i] = v_sdev
	AmpsTransient_Var[i] = v_sdev^2
	killwaves tempwave
endfor

make/o/n=(nConds) AmpsSustained_Mean, AmpsSustained_SD, AmpsSustained_Var
for (i=0;i<nConds;i+=1)
	duplicate/o/r=[][i] AmpsSustained, tempwave
	wavestats/q tempwave
	AmpsSustained_Mean[i] = v_avg
	AmpsSustained_SD[i] = v_sdev
	AmpsSustained_Var[i] = v_sdev^2
	killwaves tempwave
endfor

make/o/n=(nConds) AmpsRebound_Mean, AmpsRebound_SD, AmpsRebound_Var
for (i=0;i<nConds;i+=1)
	duplicate/o/r=[][i] AmpsRebound, tempwave
	wavestats/q tempwave
	AmpsRebound_Mean[i] = v_avg
	AmpsRebound_SD[i] = v_sdev
	AmpsRebound_Var[i] = v_sdev^2
	killwaves tempwave
endfor

if (tracetype == 0)
	duplicate/o AmpsTransient_Mean, AmpsTrans_mean
	duplicate/o AmpsTransient_SD, AmpsTrans_SD
	duplicate/o AmpsTransient_Var, AmpsTrans_Var

	duplicate/o AmpsSustained_Mean, AmpsSust_mean
	duplicate/o AmpsSustained_SD, AmpsSust_SD
	duplicate/o AmpsSustained_Var, AmpsSust_Var

	duplicate/o AmpsRebound_Mean, AmpsReb_Mean
	duplicate/o AmpsRebound_SD, AmpsReb_SD
	duplicate/o AmpsRebound_Var, AmpsReb_Var
	
	killwaves AmpsTransient_Mean, AmpsTransient_SD, AmpsTransient_Var
	killwaves AmpsSustained_Mean, AmpsSustained_SD, AmpsSustained_Var
	killwaves AmpsRebound_Mean, AmpsRebound_SD, AmpsRebound_Var
endif

if (tracetype == 2)
	duplicate/o AmpsTransient_Mean, D_AmpsTrans_mean
	duplicate/o AmpsTransient_SD, D_AmpsTrans_SD
	duplicate/o AmpsTransient_Var, D_AmpsTrans_Var

	duplicate/o AmpsSustained_Mean, D_AmpsSust_mean
	duplicate/o AmpsSustained_SD, D_AmpsSust_SD
	duplicate/o AmpsSustained_Var, D_AmpsSust_Var

	duplicate/o AmpsRebound_Mean, D_AmpsReb_Mean
	duplicate/o AmpsRebound_SD, D_AmpsReb_SD
	duplicate/o AmpsRebound_Var, D_AmpsReb_Var
	
	killwaves AmpsTransient_Mean, AmpsTransient_SD, AmpsTransient_Var
	killwaves AmpsSustained_Mean, AmpsSustained_SD, AmpsSustained_Var
	killwaves AmpsRebound_Mean, AmpsRebound_SD, AmpsRebound_Var
endif

end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Calculate Fano factor (variance/mean) for each stim condition for T/S/R response portions

Function FanoFactor(AmpsTransient_Mean, AmpsTransient_Var, AmpsSustained_Mean, AmpsSustained_Var, AmpsRebound_Mean, AmpsRebound_Var, tracetype)
wave AmpsTransient_Mean, AmpsTransient_Var, AmpsSustained_Mean, AmpsSustained_Var, AmpsRebound_Mean, AmpsRebound_Var
variable tracetype
variable i
variable nStimConds = dimsize(AmpsTransient_Mean,0)

duplicate/o AmpsTransient_Mean, MeansTemp
for (i=0;i<nStimConds;i+=1)
	if (MeansTemp[i]<0)
		MeansTemp[i]*=-1 // convert negative amp values to positive numbers (required to calc. FF)
	endif
endfor
duplicate/o AmpsTransient_Var, FanoFactor_Transient
FanoFactor_Transient/=MeansTemp // variance/mean
killwaves MeansTemp

duplicate/o AmpsSustained_mean, MeansTemp
for (i=0;i<nStimConds;i+=1)
	if (MeansTemp[i]<0)
		MeansTemp[i]*=-1
	endif
endfor
duplicate/o AmpsSustained_Var, FanoFactor_Sustained
FanoFactor_Sustained/=MeansTemp
killwaves MeansTemp

duplicate/o AmpsRebound_mean, MeansTemp
for (i=0;i<nStimConds;i+=1)
	if (MeansTemp[i]<0)
		MeansTemp[i]*=-1
	endif
endfor
duplicate/o AmpsRebound_Var, FanoFactor_Rebound
FanoFactor_Rebound/=MeansTemp
killwaves MeansTemp

if (tracetype == 0)
	duplicate/o FanoFactor_Transient, FF_Trans
	duplicate/o FanoFactor_Sustained, FF_Sust
	duplicate/o FanoFactor_Rebound, FF_Reb
	killwaves FanoFactor_Transient, FanoFactor_Sustained, FanoFactor_Rebound
endif

if (tracetype == 2)
	duplicate/o FanoFactor_Transient, D_FF_Trans
	duplicate/o FanoFactor_Sustained, D_FF_Sust
	duplicate/o FanoFactor_Rebound, D_FF_Reb
	killwaves FanoFactor_Transient, FanoFactor_Sustained, FanoFactor_Rebound
endif

end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Display response amplitudes as a function of step size

Function PlotDeconAmps(tracetype)
variable tracetype
wave stimconds
wave AmpsTrans_Mean, AmpsTrans_SD, AmpsSust_mean, AmpsSust_SD, AmpsReb_Mean, AmpsReb_SD
wave D_AmpsTrans_Mean, D_AmpsTrans_SD, D_AmpsSust_mean, D_AmpsSust_SD, D_AmpsReb_Mean, D_AmpsReb_SD

if (tracetype == 0)
	display/k=1 AmpsTrans_Mean vs stimconds
	ModifyGraph rgb=(26205,52428,1);DelayUpdate
	ErrorBars AmpsTrans_Mean Y,wave=(AmpsTrans_SD,AmpsTrans_SD)
	appendtograph AmpsSust_mean vs stimconds
	ModifyGraph rgb(AmpsSust_mean)=(1,16019,65535);DelayUpdate
	ErrorBars AmpsSust_mean Y,wave=(AmpsSust_SD,AmpsSust_SD)
	appendtograph AmpsReb_Mean vs stimconds
	ErrorBars AmpsReb_Mean Y,wave=(AmpsReb_SD,AmpsReb_SD)
	ModifyGraph zero=2,lblMargin=5,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1};DelayUpdate
	Label left "Rate of release (DF/F)";DelayUpdate
	Label bottom "Contrast step from mean light level (%)";DelayUpdate
	SetAxis/A/N=1 left
	Legend/C/N=text0/J/A=MC "\\s(AmpsTrans_Mean) Transient\r\\s(AmpsSust_Mean) Sustained\r\\s(AmpsReb_Mean) Rebound"
	Legend/C/N=text0/J/A=RT/X=0.94/Y=2.34
endif

if (tracetype == 2)
	display/k=1 D_AmpsTrans_Mean vs stimconds
	ModifyGraph rgb=(26205,52428,1);DelayUpdate
	ErrorBars D_AmpsTrans_Mean Y,wave=(D_AmpsTrans_SD,D_AmpsTrans_SD)
	appendtograph AmpsSust_mean vs stimconds
	ModifyGraph rgb(AmpsSust_mean)=(1,16019,65535);DelayUpdate
	ErrorBars AmpsSust_mean Y,wave=(AmpsSust_SD,AmpsSust_SD)
	appendtograph AmpsReb_Mean vs stimconds
	ErrorBars AmpsReb_Mean Y,wave=(AmpsReb_SD,AmpsReb_SD)
	ModifyGraph zero=2,lblMargin=5,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1};DelayUpdate
	Label left "Rate of release (F’ s-1)";DelayUpdate
	Label bottom "Contrast step from mean light level (%)";DelayUpdate
	SetAxis/A/N=1 left
	Legend/C/N=text0/J/A=MC "\\s(D_AmpsTrans_Mean) Transient\r\\s(AmpsSust_mean) Sustained\r\\s(AmpsReb_Mean) Rebound"
	Legend/C/N=text0/J/A=RT/X=0.94/Y=2.34
endif

END
