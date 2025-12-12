#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//Stimulus: dark flashes (5 - 100 ms long), 11 different stimulus conditions. 
//Function: Pull the responses to each stimulus condition and overlay in separate plots. 
//			  Overlay the mean response to each stimulus condition.
//Input: Order wave (contains order that the stimuli are delivered in)
//			Recording wave

//Output: 11 plots displaying the overlaid responses for each stimulus condition, and 1 plot overlaying the mean response to each stim condition. 

///////////////////////////////////////////////////////////////////////////	
function MakeRespMatrices_mixedOffStep_v2(order, roiMatName, firstTimePoint)
	
	wave order						//from stimulus file (1D vector, the order the different stimulus conditions are delivered in)
	string  roiMatName				// Smooth_array_copy (concatenated smoothed waves array). Sting, so put in quotation marks.  
	variable firstTimePoint  		//Exclude responses before time point X to account for adaption.
	getStimTimesMat(order, firstTimePoint) // creates matrix of start time for each stim iteration, organised into rows for stim condition. 
	wave stimTimesMat
	pullResps(stimTimesMat, roiMatName)  //don't automate (ask future Ben)

	wave RespSnips, RespSnips_Ex
	MakeMeanAndSD(RespSnips)
	MakeMeanAndSD_Ex(RespSnips_Ex)
//	DisplayRespSnips(RespSnips)
	wave MeanResp, MeanResp_Ex
	DisplayMeans(MeanResp, MeanResp_Ex)
end
///////////////////////////////////////////////////////////////////////////	



///////////////////////////////////////////////////////////////////////////	
Function getStimTimesMat(order,firstTimePoint)
wave order
variable firstTimePoint

variable nS = wavemax(order)+1 	// No. stim conditions
variable nP = dimsize(order,0)	// total number of stimulus presentations for whole protocol
variable nStimIts = nP/nS // number of stim its per conditions
variable i,j

make/o/n=(nS,nStimIts) stimTimesMat = NaN	// create matrix of stimulus condition and what time it occurs. 
make/o/n=(nS) onWhich=0

for (i=0;i<nP;i+=1)
	stimTimesMat[order[i]][onWhich[order[i]]] = 4 + i *0.4 //first number is when off-steps start in stimulus (in s), scnd no. is how frequently off-steps occur, e.g. 0.4 is every 400 ms
	onWhich[order[i]]+=1
endfor
stimtimesmat[1][0] = 4.00

variable firstStimToUse = 0
duplicate/o StimTimesMat, StimTimesMat_Ex // exclude stim iterations occuring before selected time point
for (i=0;i<dimsize(StimTimesMat,0);i+=1)
	for (j=0;j<dimsize(StimTimesMat,1);j+=1)
		if (StimTimesMat[i][j] < firstTimePoint)
			StimTimesMat_Ex[i][j] = NaN
			firstStimToUse+=1
		endif
	endfor
endfor
print "First stimulus to use: " + num2str(firstStimToUse) + " of " + num2str(nP) + " stimulus iterations"
make/o/n = (1) FirstStim
FirstStim = firstStimToUse
killwaves onWhich

// create wave of stimulus conditions
variable nStimConds = wavemax(order) + 1
make/o/n=(nStimConds) StimConds
StimConds[0]= 5
StimConds[1]= 10
StimConds[2]= 12
StimConds[3]= 14
StimConds[4]= 16
StimConds[5]= 18
StimConds[6]= 20
StimConds[7]= 30
StimConds[8]= 40
StimConds[9]= 50
StimConds[10]= 100

// create stimSnips for display purposes
make/o/n=(400,nStimConds) stimSnips
SetScale/P x 0,0.001,"", stimSnips
stimSnips=1
for (i=0;i<nStimConds;i+=1)
	stimSnips[50,50+stimConds[i]][i] = 0
endfor

end
///////////////////////////////////////////////////////////////////////////	

// Cut response snippets in RespSnips matrix

Function pullResps(stimTimesMat, roiMatName) //pulls out the responses to the different stimuli types
wave stimTimesMat
string roiMatName

variable winTime = 0.4		//snippet length after stim onset (in s)
variable counter

duplicate/o $roiMatName, roiMat
variable nStimTypes = dimsize(stimTimesMat,0) // number of stim conditions
variable nPer = dimsize(stimTimesMat,1)		// number of itertions per condition
variable dt = deltax(roiMat)						//delta scaling
setscale/p x,0,dt, roiMat
variable i,j,k,l
variable len = (winTime)/dt + 1

variable cutBeforeStim = 0.05 // time before stim onset to cut response at (s)
duplicate/o stimTimesMat, stimTimesMat_shiftd
stimTimesMat_shiftd-= cutBeforeStim
	
make/o/n=(len,nPer,nStimTypes) pulledResps		// makes matrix of responses, columns are stim its, layers are stim conds
setscale/p x,0,dt, pulledResps
	for (j=0;j<nStimTypes;j+=1)
		for (k=0;k<nPer;k+=1)
			pulledResps[][k][j] = roiMat[x2pnt(pulledResps,stimTimesMat_shiftd[j][k])+p]
			Make/O/N = (dimsize(pulledresps, 0)) singletrace =  pulledResps[p][k][j]
			SetScale/P x, 0, dt, ""  singletrace
			Wavestats/Q /R=[0, (0.02/dt)] singletrace
		endfor
	endfor				
waveclear pulledResps
killwaves/z pulledResps
duplicate/o pulledResps, RespSnips
killwaves pulledResps, singletrace

wave stimTimesMat_Ex
make/o/n=(len,nPer,nStimTypes) pullResp	= NaN// makes matrix of responses excluding first X resps
setscale/p x,0,dt, pullResp
	for (j=0;j<nStimTypes;j+=1)
		for (k=0;k<nPer;k+=1)
			if (numtype(stimTimesMat_Ex[j][k]) == 2)
				pullResp[][k][j] = NaN
			elseif (numtype(StimTimesMat_Ex[j][k]) == 0)
				pullResp[][k][j] = roiMat[x2pnt(pullResp,stimTimesMat_shiftd[j][k])+p]
				Make/O/N = (dimsize(pullResp, 0)) singletrace =  pullResp[p][k][j]
				SetScale/P x, 0, dt, ""  singletrace
				Wavestats/Q /R=[0, (0.02/dt)] singletrace
			endif
		endfor
	endfor				
duplicate/o pullResp, RespSnips_Ex
killwaves pullResp, stimTimesMat_shiftd, singletrace
end

/////////////////////////////////////////////////////////////////////////////////

// calculate mean and SD

Function MakeMeanAndSD(w) // use RespSnips
wave w

variable nP = Dimsize(w,0)
variable nStimReps = Dimsize(w,1)
variable nStimConds = Dimsize(w, 2)
make /o/n=(nP) Average = 0
make /o/n=(nP) SD = 0
variable counter
variable i
wave stimConds

for (i=0;i<nStimConds;i+=1) // get mean and SD per stim condition
	for (counter=0;counter<nP;counter+=1)
		make /o/n=(nStimReps) currentwave = w[counter][p][i]
		WaveStats/Q currentwave
		variable CurrentAverage = V_Avg
		variable currentSD = V_SDev
		Average[counter]=Currentaverage
		SD[counter]=CurrentSD
		SetScale/P x 0,0.001,"", Average, SD 
	endfor
	concatenate/np=1 {Average}, Means
	concatenate/np=1 {SD}, SDs
endfor
duplicate/o Means, MeanResp
duplicate/o SDs, MeanResp_SD
killwaves Average, SD, currentwave, Means, SDs

end

// calculate mean and SD exlucind first X responses

Function MakeMeanAndSD_Ex(w) // use RespSnips_Ex
wave w

variable nP = Dimsize(w,0)
variable nStimReps = Dimsize(w,1)
variable nStimConds = Dimsize(w, 2)
make /o/n=(nP) Average = 0
make /o/n=(nP) SD = 0
variable counter
variable i
wave stimConds

for (i=0;i<nStimConds;i+=1) // get mean and SD per stim condition
	for (counter=0;counter<nP;counter+=1)
		make /o/n=(nStimReps) currentwave = w[counter][p][i]
		WaveStats/Q currentwave
		variable CurrentAverage = V_Avg
		variable currentSD = V_SDev
		Average[counter]=Currentaverage
		SD[counter]=CurrentSD
		SetScale/P x 0,0.001,"", Average, SD 
	endfor
	concatenate/np=1 {Average}, Means
	concatenate/np=1 {SD}, SDs
endfor
duplicate/o Means, MeanResp_Ex
duplicate/o SDs, MeanResp_SD_Ex
killwaves Average, SD, currentwave, Means, SDs

end

///////////////////////////////////////////////////////////////////////////

// display response snippets with mean overlaid

Function DisplayRespSnips(RespSnips)
wave 	RespSnips
wave MeanResp
variable nStimReps = dimsize(RespSnips, 1)
variable nStimConds = dimsize(RespSnips, 2)
variable i, j
wave stimConds
wave stimSnips

for (i=0;i<nStimConds;i+=1)
	display/k=1 RespSnips[][0][i]
	for (j=1;j<nStimReps;j+=1)
		appendtograph RespSnips[][j][i]
	endfor
	modifygraph rgb=(0,0,0)
	appendtograph stimsnips[][i]
	ModifyGraph offset(stimSnips)={0,-2}
	SetAxis/A/N=1 left;DelayUpdate
	ModifyGraph zero(left)=2,lblMargin=5,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1};DelayUpdate
	Label left "Glutamate release (F’ s-1)";DelayUpdate
	Label bottom "Time (s)"
	string StimCondName = num2str(stimConds[i]) + "ms ISI"
	DrawText 0.652272727272727,0.0700934579439252, StimCondName
endfor
end

Function DisplayMeans(MeanResp, MeanResp_Ex)
wave MeanResp, MeanResp_Ex

variable nStimConds = dimsize(MeanResp,1)
variable i

display/k=1 MeanResp[][0]
for (i=1;i<nStimConds;i+=1)
	appendtograph MeanResp[][i]
endfor
SetAxis/A/N=1 left;DelayUpdate
ModifyGraph zero(left)=2,lblMargin=5,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1};DelayUpdate
Label left "Glutamate release (F’ s-1)";DelayUpdate
Label bottom "Time (s)"
DrawText 0.0117370892018779,0.0467289719626168,"Mean response for each stimulus condition"

display/k=1 MeanResp_Ex[][0]
for (i=1;i<nStimConds;i+=1)
	appendtograph MeanResp_Ex[][i]
endfor
SetAxis/A/N=1 left;DelayUpdate
ModifyGraph zero(left)=2,lblMargin=5,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1};DelayUpdate
Label left "Glutamate release (F’ s-1)";DelayUpdate
Label bottom "Time (s)"
DrawText 0.0117370892018779,0.0467289719626168,"Mean response for each stimulus condition (excluding first resps)"

end

/////////////////////////////////////////////////////////////////////////////////

// zero the response snippets based on the first 50 ms of the response snippet (before stim onset)

Function ZeroSnips()
wave RespSnips
variable i, j
variable nStimReps = dimsize(RespSnips, 1)
variable nStimConds = dimsize(RespSnips,2)

duplicate/o RespSnips, RespSnips_z //zero the pulled resps 
for (i=0;i<nStimConds;i+=1)
	for (j=0;j<nStimReps;j+=1)
		duplicate/o/r=[0,50][j][i] RespSnips_z, tempsnip
		wavestats/q tempsnip
		RespSnips_z[][j][i]-=v_avg
	endfor
endfor

killwaves tempsnip

end