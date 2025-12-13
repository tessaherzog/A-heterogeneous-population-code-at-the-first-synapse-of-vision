#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//Cut recording into snippets

Function Sin20Hz_MakeArrays(w)
wave w // recording
CutTrace(w)
GetMeanResps()
GetMean_z_Resps()
DisplaySinSnips()

END

Function CutTrace(w)
wave w
variable SinHz = 20 // Sinusoid at 20 Hz
variable SinStart = 8000 // sinusoid starts 8 s into stimulus protocol
variable SinEnd = 38000
variable SinDur = SinEnd - SinStart
variable CycleDur = 1000/SinHz
variable nStimIts = ((Sindur)/1000)*SinHz
print nStimIts

wave StimStartTimes
killwaves StimStartTimes
make/o/n=(nStimIts) StimStartTimes = NaN //get stim start times
variable i
for (i=0;i<nStimIts;i+=1)
	StimStartTimes[i] = SinStart+(CycleDur*i)
endfor

killwindow/z RespSnipGraph // kill display windows to allow snips matrices to be deleted
killwindow/z RespSnipZGraph

wave RespSnips
killwaves RespSnips
for (i=0;i<nStimIts;i+=1) // cut trace into snippest
	duplicate/o/r=[StimStartTimes[i]+25,StimStartTimes[i]+CycleDur+25+25][] w, tempsnip
	Redimension/N=-1 tempsnip
	SetScale/P x 0,0.001,"", tempsnip
	concatenate/np=1 {tempsnip}, RespSnips
	killwaves tempsnip
endfor

// z-shift the response snips to respone min (trough)
duplicate/o RespSnips, RespSnips_zShift
for (i=0;i<nStimIts;i+=1)
	duplicate/o/r=[][i] RespSnips, tempSnip
	Redimension/N=-1 tempsnip
	RespSnips_zShift[][i]-=wavemin(tempsnip)
	killwaves tempsnip
endfor

END

Function GetMeanResps()
wave RespSnips
variable SnipLen = dimsize(RespSnips,0)
make/o/n=(SnipLen) MeanResp
make/o/n=(SnipLen) MeanResp_SD
make/o/n=(SnipLen) MedianResp

variable i
for (i=0;i<SnipLen;i+=1)
	duplicate/o/r=[i][]RespSnips, temp
	wavestats/q temp
	MeanResp[i] = v_avg
	MeanResp_SD[i] = v_sdev
	MedianResp[i] = statsmedian(temp)
	killwaves temp
endfor
SetScale/P x 0,0.001,"", MeanResp,MeanResp_SD, MedianResp
END

Function GetMean_z_Resps()
wave RespSnips_zShift
variable SnipLen = dimsize(RespSnips_zShift,0)
make/o/n=(SnipLen) MeanResp_Z
make/o/n=(SnipLen) MeanResp_Z_SD
make/o/n=(SnipLen) MedianResp_Z

variable i
for (i=0;i<SnipLen;i+=1)
	duplicate/o/r=[i][]RespSnips_zShift, temp
	wavestats/q temp
	MeanResp_Z[i] = v_avg
	MeanResp_Z_SD[i] = v_sdev
	MedianResp_Z[i] = statsmedian(temp)
	killwaves temp
endfor
SetScale/P x 0,0.001,"", MeanResp_Z,MeanResp_Z_SD,MedianResp_Z
END

Function DisplaySinSnips()
wave RespSnips, RespSnips_zShift, MeanResp, MeanResp_Z
variable i
variable nStimIts = dimsize(RespSnips,1)

display/k=1/n=RespSnipGraph RespSnips[][0] //overlay RespSnips
for (i=1;i<nStimIts;i+=1)
	appendtograph RespSnips[][i]
endfor
SetAxis/A/N=1 left;DelayUpdate
ModifyGraph lblMargin=5,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1};DelayUpdate
Label left "Glutamate release (F's'\\S-1\\M)";DelayUpdate
Label bottom "Time (s)"
ModifyGraph rgb=(0,0,0,3277)
ModifyGraph width=141.732,height=141.732
appendtograph MeanResp
ModifyGraph lsize(MeanResp)=2

display/k=1/n=RespSnipZGraph RespSnips_zShift[][0] //overlay RespSnips_zShift (trough alined)
for (i=1;i<nStimIts;i+=1)
	appendtograph RespSnips_zShift[][i]
endfor
SetAxis/A/N=1 left;DelayUpdate
ModifyGraph lblMargin=5,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1};DelayUpdate
Label left "Glutamate release (F's'\\S-1\\M)";DelayUpdate
Label bottom "Time (s)"
ModifyGraph rgb=(0,0,0,3277)
ModifyGraph width=141.732,height=141.732
appendtograph MeanResp_Z
ModifyGraph lsize(MeanResp_Z)=2

END