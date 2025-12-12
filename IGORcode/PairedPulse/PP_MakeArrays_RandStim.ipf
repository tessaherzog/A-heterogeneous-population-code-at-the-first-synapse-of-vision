#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// 2023.02.10
// updated 2023/09/30
// Function snips the recording into an array. 
// for use with recordings to PP stimulus where...
// ISI = 2 to 100
// Order is randomised

Function MakeArrays_PP_Rand2to100(recording, firststimtouse) // use name of recording wave
wave recording
variable firststimtouse

GetStimTimes(recording, firststimtouse) // Matrix of stim start times

wave StimTimesMat // build matrix of stimulus responses from trace
SnipRec(recording, StimTimesMat)
wave RespSnips, RespSnips_FSTU
GetMeanResps(RespSnips)
GetMeanResp_FSTU(RespSnips_FSTU)

wave decontrace
SnipRec_Decon(deconTrace, StimTimesMat) // build matrix of stimulus responses from decon trace
wave RespSnips_decon, RespSnips_decon_FSTU
GetMeanResps_decon(RespSnips_decon)
GetMeanResp_decon_FSTU(RespSnips_decon_FSTU)
MakeStimSnips()
end

//////////////////////////////////////////////////////////////////////////////////////////////////

Function GetStimTimes(recording, firststimtouse) // use recording wave as input
wave recording
variable firststimtouse
wave order
variable nStimConds = wavemax(order)+1 // make wave of stimulus conditions
make/o/n=(nStimConds) StimConds
StimConds[0] = 2
StimConds[1] = 5
StimConds[2] = 10
StimConds[3] = 20
StimConds[4] = 30
StimConds[5] = 40
StimConds[6] = 50
StimConds[7] = 60
StimConds[8] = 70
StimConds[9] = 80
StimConds[10] = 90
StimConds[11] = 100

variable offStep = 40 // off step = 40 ms
variable pairISI = 700 // ISI between pairs of pulses = 400 ms
variable nStimReps = 5 // number of times each stimulus condition is repeated
variable stimstart = 4000 // paired pulses start 6.85 s into stimulus after 5X 40ms ISI pairs to allow the retina to warm up

// lengths of stimulus snippet for each stimulus condition
variable i
make/o/n=(nStimConds) StimConds_Lens
for (i=0;i<nStimConds;i+=1)
	StimConds_Lens[i] = offstep*2 + StimConds[i] + pairISI
endfor

// Make wave of pair start times
variable nP = nStimConds*nStimReps
make/o/n=(nP) stimStartTimes
stimStartTimes[0] = stimStart
for (i=1;i<nP;i+=1)
	stimStartTimes[i] = stimstarttimes[i-1] + StimConds_Lens[order[i-1]]
endfor

// make matrix of start times, columns for each stim conds
make/o/n=(nStimReps,nStimConds) StimTimesMat
make/o/n=(nStimConds) onWhich = 0
for (i=0;i<nP;i+=1)
	StimTimesMat[onWhich[order[i]]][order[i]] = stimstartTimes[i]
	onWhich[order[i]]+=1
endfor
killwaves onWhich

// make matrix of start times starting from the "first stim to use"

make/o/n=(nStimReps,nStimConds) StimTimesMat_FSTU
make/o/n=(nStimConds) onWhich = 0
for (i=0;i<nP;i+=1)
	if (i>firstStimToUse-1)
		StimTimesMat_FSTU[onWhich[order[i]]][order[i]] = stimstartTimes[i]
		onWhich[order[i]]+=1
	else
		StimTimesMat_FSTU[onWhich[order[i]]][order[i]] = NaN
		onWhich[order[i]]+=1
	endif
endfor
killwaves onWhich

end

//////////////////////////////////////////////////////////////////////////////////////////////////

Function SnipRec(recording, StimTimesMat) // Cut responses into snipet in a matrix, layered by stim cond
wave recording, StimTimesMat
wave StimTimesMat_FSTU

wave StimConds_Lens
variable winSize = wavemin(StimConds_Lens)
variable i, j
variable nStimReps = dimsize(StimTimesMat,0)
variable nStimConds = dimsize(StimTimesMat,1)

wave RespSnips
killwaves RespSnips
for (i=0;i<nStimConds;i+=1) // Make matrix of ALL response snippets
	for (j=0;j<nStimReps;j+=1)
		if (numtype(StimTimesMat[j][i]) == 2)
			make/o/n=(winsize+50) temp = Nan
		else
			duplicate/o/r=[StimTimesMat[j][i]-50,StimTimesMat[j][i]+winSize-1]recording, temp
			SetScale/P x 0,0.001,"", temp
			Redimension/N=-1 temp
		endif
			concatenate/np=1 {temp}, Snips
			killwaves temp
	endfor
	concatenate/np=2 {Snips}, RespSnips
	killwaves snips
endfor

wave RespSnips_FSTU
killwaves RespSnips_FSTU
for (i=0;i<nStimConds;i+=1) // make matrix of response snippets from First Stim To Use onwards
	for (j=0;j<nStimReps;j+=1)
		if (numtype(StimTimesMat_FSTU[j][i]) == 2)
			make/o/n=(winsize+50) temp = Nan
		else
			duplicate/o/r=[StimTimesMat_FSTU[j][i]-50,StimTimesMat_FSTU[j][i]+winSize-1]recording, temp
			SetScale/P x 0,0.001,"", temp
			Redimension/N=-1 temp
		endif
			concatenate/np=1 {temp}, Snips
			killwaves temp
	endfor
	concatenate/np=2 {Snips}, RespSnips_FSTU
	killwaves snips
endfor
SetScale/P x 0,0.001,"", RespSnips,RespSnips_FSTU

end

//////////////////////////////////////////////////////////////////////////////////////////////////

Function GetMeanResps(RespSnips) // calculate the mean response for each stim cond from RespSnips
wave RespSnips

variable nP = Dimsize(RespSnips,0)
variable nStimReps = dimsize(RespSnips,1)
variable nStimConds = dimsize(RespSnips,2)
make /o/n=(nP) Average = 0
make /o/n=(nP) SD = 0
variable counter, i

for (i=0;i<nStimConds;i+=1)
	for (counter=0;counter<nP;counter+=1)
		make /o/n=(nStimReps) currentwave = RespSnips[counter][p][i]
		WaveStats/Q currentwave
		variable CurrentAverage = V_Avg
		variable currentSD = V_SDev
		Average[counter]=Currentaverage
		SD[counter]=CurrentSD
		SetScale/P x 0,0.001,"", Average, SD 
	endfor
	concatenate/np=1 {Average}, Aves
	concatenate/np=1 {SD}, SDs
endfor
killwaves Average, SD, currentwave

duplicate/o Aves, RespMeans
duplicate/o SDs, RespMeans_SD
killwaves Aves, SDs
end

//////////////////////////////////////////////////////////////////////////////////////////////////

Function GetMeanResp_FSTU(RespSnips_FSTU) // calculate the mean response for each stim cond from RespSnips
wave RespSnips_FSTU

variable nP = Dimsize(RespSnips_FSTU,0)
variable nStimReps = dimsize(RespSnips_FSTU,1)
variable nStimConds = dimsize(RespSnips_FSTU,2)
make /o/n=(nP) Average = 0
make /o/n=(nP) SD = 0
variable counter, i

for (i=0;i<nStimConds;i+=1)
	for (counter=0;counter<nP;counter+=1)
		make /o/n=(nStimReps) currentwave = RespSnips_FSTU[counter][p][i]
		WaveStats/Q currentwave
		variable CurrentAverage = V_Avg
		variable currentSD = V_SDev
		Average[counter]=Currentaverage
		SD[counter]=CurrentSD
		SetScale/P x 0,0.001,"", Average, SD 
	endfor
	concatenate/np=1 {Average}, Aves
	concatenate/np=1 {SD}, SDs
endfor
killwaves Average, SD, currentwave

duplicate/o Aves, RespMeans_SFTU
duplicate/o SDs, RespMeans_SD_STFU
killwaves Aves, SDs

end

//////////////////////////////////////////////////////////////////////////////////////////////////
// SAME AGAIN but for decon trace

Function SnipRec_Decon(deconTrace, StimTimesMat) // Cut responses into snipet in a matrix, layered by stim cond
wave deconTrace, StimTimesMat
wave StimTimesMat_FSTU

wave StimConds_Lens
variable winSize = wavemin(StimConds_Lens)
variable i, j
variable nStimReps = dimsize(StimTimesMat,0)
variable nStimConds = dimsize(StimTimesMat,1)

wave RespSnips_decon
killwaves RespSnips_decon
for (i=0;i<nStimConds;i+=1) // Make matrix of ALL response snippets
	for (j=0;j<nStimReps;j+=1)
		if (numtype(StimTimesMat[j][i]) == 2)
			make/o/n=(winsize+50) temp = Nan
		else
			duplicate/o/r=[StimTimesMat[j][i]-50,StimTimesMat[j][i]+winSize-1]deconTrace, temp
			SetScale/P x 0,0.001,"", temp
			Redimension/N=-1 temp
		endif
			concatenate/np=1 {temp}, Snips
			killwaves temp
	endfor
	concatenate/np=2 {Snips}, RespSnips_decon
	killwaves snips
endfor

wave RespSnips_decon_FSTU
killwaves RespSnips_decon_FSTU
for (i=0;i<nStimConds;i+=1) // make matrix of response snippets from First Stim To Use onwards
	for (j=0;j<nStimReps;j+=1)
		if (numtype(StimTimesMat_FSTU[j][i]) == 2)
			make/o/n=(winsize+50) temp = Nan
		else
			duplicate/o/r=[StimTimesMat_FSTU[j][i]-50,StimTimesMat_FSTU[j][i]+winSize-1]deconTrace, temp
			SetScale/P x 0,0.001,"", temp
			Redimension/N=-1 temp
		endif
			concatenate/np=1 {temp}, Snips
			killwaves temp
	endfor
	concatenate/np=2 {Snips}, RespSnips_decon_FSTU
	killwaves snips
endfor

SetScale/P x 0,0.001,"", RespSnips_decon,RespSnips_decon_FSTU

end

//////////////////////////////////////////////////////////////////////////////////////////////////

Function GetMeanResps_decon(RespSnips_decon) // calculate the mean response for each stim cond from RespSnips
wave RespSnips_decon

variable nP = Dimsize(RespSnips_decon,0)
variable nStimReps = dimsize(RespSnips_decon,1)
variable nStimConds = dimsize(RespSnips_decon,2)
make /o/n=(nP) Average = 0
make /o/n=(nP) SD = 0
variable counter, i

for (i=0;i<nStimConds;i+=1)
	for (counter=0;counter<nP;counter+=1)
		make /o/n=(nStimReps) currentwave = RespSnips_decon[counter][p][i]
		WaveStats/Q currentwave
		variable CurrentAverage = V_Avg
		variable currentSD = V_SDev
		Average[counter]=Currentaverage
		SD[counter]=CurrentSD
		SetScale/P x 0,0.001,"", Average, SD 
	endfor
	concatenate/np=1 {Average}, Aves
	concatenate/np=1 {SD}, SDs
endfor
killwaves Average, SD, currentwave

duplicate/o Aves, RespMeans_decon
duplicate/o SDs, RespMeans_decon_SD
killwaves Aves, SDs
end

//////////////////////////////////////////////////////////////////////////////////////////////////

Function GetMeanResp_decon_FSTU(RespSnips_decon_FSTU) // calculate the mean response for each stim cond from RespSnips
wave RespSnips_decon_FSTU

variable nP = Dimsize(RespSnips_decon_FSTU,0)
variable nStimReps = dimsize(RespSnips_decon_FSTU,1)
variable nStimConds = dimsize(RespSnips_decon_FSTU,2)
make /o/n=(nP) Average = 0
make /o/n=(nP) SD = 0
variable counter, i

for (i=0;i<nStimConds;i+=1)
	for (counter=0;counter<nP;counter+=1)
		make /o/n=(nStimReps) currentwave = RespSnips_decon_FSTU[counter][p][i]
		WaveStats/Q currentwave
		variable CurrentAverage = V_Avg
		variable currentSD = V_SDev
		Average[counter]=Currentaverage
		SD[counter]=CurrentSD
		SetScale/P x 0,0.001,"", Average, SD 
	endfor
	concatenate/np=1 {Average}, Aves
	concatenate/np=1 {SD}, SDs
endfor
killwaves Average, SD, currentwave

duplicate/o Aves, RespMeans_decon_SFTU
duplicate/o SDs, RespMeans_decon_SD_STFU
killwaves Aves, SDs

end

//////////////////////////////////////////////////////////////////////////////////////////////////

Function zeroSnipResps(RespSnips) 
// optional baseline shift of RespSnips to account for drift.

wave RespSnips
variable i, j
variable nStimConds = dimsize(RespSnips,2)
variable nStimReps = dimsize(RespSnips, 1)

duplicate/o RespSnips, RespSnips_z //zero the pulled resps 
for (i=0;i<nStimConds;i+=1)
	for (j=0;j<nStimReps;j+=1)
		duplicate/o/r=[0,50][j][i] RespSnips_z, tempsnip
		wavestats/q tempsnip
		RespSnips_z[][j][i]-=v_avg
	endfor
endfor

killwaves tempsnip

// calculate the mean zeroed responses from RespSnips_z
wave RespMeans_z, RespMeans_z_SD
killwaves RespMeans_z, RespMeans_z_SD

variable nP = Dimsize(RespSnips_z,0)

make /o/n=(nP) Average = 0
make /o/n=(nP) SD = 0
variable counter

for (i=0;i<nStimConds;i+=1) // make the average from the zeroed waves
	for (counter=0;counter<nP;counter+=1)
		make /o/n=(nStimReps) currentwave = RespSnips_z[counter][p][i]
		WaveStats/Q currentwave
		variable CurrentAverage = V_Avg
		variable currentSD = V_SDev
		Average[counter]=Currentaverage
		SD[counter]=CurrentSD
		SetScale/P x 0,0.001,"", Average, SD 
	endfor
	concatenate/np=1 {Average}, RespMeans_z
	concatenate/np=1 {SD}, RespMeans_z_SD
endfor
killwaves Average, SD, currentwave

end

///////////////////////////////////////////////////////////////////////////////////////////////////

Function MakeStimSnips() // make wave of the stimulus steps for each condition for display purposes
wave RespSnips
wave StimConds
variable SnipLen = dimsize(RespSnips,0)
variable nStimReps = dimsize(RespSnips, 1)
variable nStimConds = dimsize(RespSnips, 2)

make/o/n=(50) PreStim = 1
make/o/n=(40) OffStep = 0
make/o/n=(700) PairISI = 1

wave StimSnips
killwaves StimSnips
variable i
for (i=0;i<nStimConds;i+=1)
	make/o/n=(StimConds[i]) ISI = 1
	concatenate/o {PreStim, offStep, ISI, OffStep, PairISI}, StimSnipTemp
	DeletePoints 830,dimsize(ISI,0), StimSnipTemp
	concatenate/np=1 {StimSnipTemp}, StimSnips
	killwaves StimSnipTemp
endfor
SetScale/P x 0,0.001,"", StimSnips

killwaves ISI, OffStep, PairISI, PreStim

end

