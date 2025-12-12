#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// Cut responses to train stim into matrices

Function TrainStim_MakeRespMatrices(offstep, firstStimToUse)
variable offstep // duration of off step in train
variable firstStimToUse // first stimulus response # to use, if responses ramp up

GetResponseSnippets(Offstep,firstStimToUse)
AverageResponses()
DisplaySnips()

END

/////////////////////////////////////////////////////////////////////////////////////////

Function GetResponseSnippets(offstep, firststimtouse)

variable offstep
variable firststimtouse
variable ISI = 460 // 460 ms between end of stim and start of next stim
variable stimStart = 4000 // off-steps start 4 s into stimulus protocol
variable nStimReps = 98 // standard # of reps in the existing stimuli
variable i

make/o/n=(nStimReps) StimStartTimes // make wave of stim start times
StimStartTimes[0] = stimStart
for (i=1;i<nStimReps;i+=1)
	StimStartTimes[i] = StimStartTimes[i-1] + offstep + ISI
endfor

// make matrix of response snippets (normal trace)
wave Trace
variable cutPreStim = 50 // cut the response snippet 50 ms before stim onset

for (i=0;i<nStimReps;i+=1)
	duplicate/o/r=[stimstarttimes[i]-cutPreStim, stimstarttimes[i]+ offstep + ISI -1]Trace, tempSnip
	Redimension/N=-1 tempSnip
	SetScale/P x 0,0.001,"", tempSnip
	concatenate/np=1 {tempSnip}, Snips
	killwaves tempSnip
endfor
duplicate/o Snips, RespSnips
killwaves Snips
RespSnips[][,firststimtouse] = NaN

// make matrix of response snippets (Deconvolved trace)
wave Trace_Decon
for (i=0;i<nStimReps;i+=1)
	duplicate/o/r=[stimstarttimes[i]-cutPreStim, stimstarttimes[i]+ offstep + ISI -1]Trace_Decon, tempSnip
	Redimension/N=-1 tempSnip
	SetScale/P x 0,0.001,"", tempSnip
	concatenate/np=1 {tempSnip}, Snips
	killwaves tempSnip
endfor
duplicate/o Snips, RespSnips_Decon
killwaves Snips
RespSnips_Decon[][,firststimtouse] = NaN

// make a wave of a single stimulus iteration for display purposes

make/o/n=(dimsize(RespSnips,0)) stimSnip // make wave of stimulus for display purposes
StimSnip = 1
StimSnip[cutPreStim, cutPreStim+offstep] = 0
SetScale/P x 0,0.001,"", stimSnip
end

/////////////////////////////////////////////////////////////////////////////////

// not included for this analysis.
// zero the response snippets based on the first 50 ms of the response snippet (before stim onset)

Function ZeroTrainRespSnips()
wave RespSnips_decon
variable i
variable nStimReps = dimsize(RespSnips_decon, 1)

duplicate/o RespSnips_decon, RespSnips_decon_z //zero the pulled resps 
for (i=0;i<nStimReps;i+=1)
	duplicate/o/r=[0,50][i] RespSnips_decon_z, tempsnip
	wavestats/q tempsnip
	RespSnips_decon_z[][i]-=v_avg
endfor

killwaves tempsnip

end

/////////////////////////////////////////////////////////////////////////////////

// Calculate mean and SD response

Function AverageResponses()
wave RespSnips, RespSnips_decon

make/o/n=(dimsize(RespSnips,0)) MeanResp, MeanResp_Decon
make/o/n=(dimsize(RespSnips,0)) MeanResp_SD, MeanResp_SD_Decon

variable i
for (i=0;i<dimsize(RespSnips,0);i+=1)
	duplicate/o/r=[i][] RespSnips,temp
	wavestats/q temp
	MeanResp[i] = v_avg
	MeanResp_SD[i] = v_sdev
	killwaves temp
endfor

for (i=0;i<dimsize(RespSnips,0);i+=1)
	duplicate/o/r=[i][] RespSnips_decon,temp
	wavestats/q temp
	MeanResp_Decon[i] = v_avg
	MeanResp_SD_Decon[i] = v_sdev
	killwaves temp
endfor

SetScale/P x 0,0.001,"", MeanResp,MeanResp_Decon,MeanResp_SD,MeanResp_SD_Decon

END

///////////////////////////////////////////////////////////////////////////

// display response snippets with mean overlaid

Function DisplaySnips()
wave RespSnips, MeanResp, RespSnips_Decon, MeanResp_Decon, StimSnip
variable nStimReps = dimsize(RespSnips, 1)
variable i


display/k=1 RespSnips[][0]
for (i=1;i<nStimReps;i+=1)
	appendtograph RespSnips[][i]
endfor
modifygraph rgb=(0,0,0,13107)
appendtograph MeanResp
appendtograph stimsnip
ModifyGraph offset(stimSnip)={0,-2}
SetAxis/A/N=1 left;DelayUpdate
ModifyGraph zero(left)=2,lblMargin=5,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1};DelayUpdate
Label left "Glutamate release (DF/F)";DelayUpdate
Label bottom "Time (s)"
DrawText 0.0318181818181818,0.0467289719626168,"DF/F responses"


display/k=1 RespSnips_decon[][0]
for (i=1;i<nStimReps;i+=1)
	appendtograph RespSnips_decon[][i]
endfor
modifygraph rgb=(0,0,0,13107)
appendtograph MeanResp_decon
appendtograph stimsnip
ModifyGraph offset(stimSnip)={0,-2}
SetAxis/A/N=1 left;DelayUpdate
ModifyGraph zero(left)=2,lblMargin=5,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1};DelayUpdate
Label left "Glutamate release (F’ s-1)";DelayUpdate
Label bottom "Time (s)"
DrawText 0.0318181818181818,0.0467289719626168,"Deconvolved responses"

end
