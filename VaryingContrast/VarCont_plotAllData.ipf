#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// Display plots for individual synapses (normal and deconvolved waves)
// a) Mean responses. Superposition of mean response to each stimulus condition.
// b) Mean response +/- SD. Responses plotted side by side as a function of stimulus condition.
// c) Response amplitudes. For transient, sustained and rebound portions, as a function of contrast step.
// d) Temporal jitter. SD in time to half peak as a funciton of stimulus condition.
// e) Adaption index. Response to -100% contrast with adaption index printed on graph.
// f) DLi. AUC (500 ms window) as a function of stimulus condtion, with dark-light index printed on graph.
// g) Baseline. Plot shifted traces with baseline label. 

Function PlotData(recName, tracetype)
string recName
variable tracetype // 0 = s wave, 1 = decon wave, 2 = decon wave less smoothing

wave RespMeans_z, AmpsTrans_Mean, AmpsSust_Mean, AmpsReb_Mean, TransPeak_TtoHP_SD
wave RespSnips_z, RespMeans_SD_Z, RespMeans_z, AdaptationIndex_mean, AdaptationIndex_SD
wave DLi_RespAUC_mean_0X, DLi_RespAUC_SD_0X, DLivalue
wave RespMeans_z, Baseline_Value
if (tracetype == 0)
	MeanResponse_plot(RespMeans_z, tracetype)
	SideBySide_Plot(RespMeans_z, RespMeans_SD_Z, tracetype)
	ResponseAmplitudes_plot(AmpsTrans_Mean, AmpsSust_Mean, AmpsReb_Mean, tracetype)
	TemporalJitter_Plot(TransPeak_TtoHP_SD)
	AdaptionIndex_plot(RespSnips_z, RespMeans_z, AdaptationIndex_mean, AdaptationIndex_SD, tracetype)
	DLi_Plot(DLi_RespAUC_mean_0X, DLi_RespAUC_SD_0X, DLivalue)
	Baseline_Plot(RespMeans_z, Baseline_Value, tracetype)
	AddLegend_Plot(0)
endif

wave D_RespMeans_z, D_AmpsTrans_Mean, D_AmpsSust_Mean, D_AmpsReb_Mean, D_TransPeak_TtoHP_SD
wave D_RespSnips_z, D_RespMeans_SD_Z, D_RespMeans_z, D_AdaptationIndex_mean, D_AdaptationIndex_SD
wave D_DLi_RespAUC_mean_0X, D_DLi_RespAUC_SD_0X, D_DLivalue
wave D_RespMeans_z, D_Baseline_Value
if (tracetype == 2)
	MeanResponse_plot(D_RespMeans_z, tracetype)
	SideBySide_Plot(D_RespMeans_z, D_RespMeans_SD_Z, tracetype)
	ResponseAmplitudes_plot(D_AmpsTrans_Mean, D_AmpsSust_Mean, D_AmpsReb_Mean, tracetype)
	TemporalJitter_Plot(D_TransPeak_TtoHP_SD)
	AdaptionIndex_plot(D_RespSnips_z, D_RespMeans_z, D_AdaptationIndex_mean, D_AdaptationIndex_SD, tracetype)
	DLi_Plot(D_DLi_RespAUC_mean_0X, D_DLi_RespAUC_SD_0X, D_DLivalue)
	Baseline_Plot(D_RespMeans_z, D_Baseline_Value, tracetype)
	AddLegend_Plot(2)
endif

// add name of recording wave to top left hand corner of plot
SetDrawEnv textrot = 90, xcoord= abs,ycoord= abs;DelayUpdate
DrawText 10,80,recName

end

// a) Mean response superposition
Function MeanResponse_Plot(w, tracetype) // RespMeans_Z or RespMeans_decon
wave w
variable tracetype

display/k=1/L=RespMeansL/B=RespMeansB w[][0]
ModifyGraph width=708,height=425
variable i
variable nStimConds = dimsize(w,1)

for (i=1;i<nStimConds;i+=1)
	appendToGraph /L=RespMeansL/B=RespMeansB w[][i]
endfor

// 
ModifyGraph rgb=(0,0,0)
ModifyGraph lblPos(RespMeansL)=50,lblPos(RespMeansB)=40;DelayUpdate
Label RespMeansL "DF/F";DelayUpdate
Label RespMeansB "Time (ms)"
SetAxis/A/N=1 RespMeansL

// draw red dotted line at stim onset and offset
wavestats/q w
SetDrawEnv xcoord= RespMeansB,ycoord= RespMeansL,linefgc= (65535,0,0),dash= 1;DelayUpdate
DrawLine 0.5,v_min,0.5,v_max
SetDrawEnv xcoord= RespMeansB,ycoord= RespMeansL,linefgc= (65535,0,0),dash= 1;DelayUpdate
DrawLine 1,v_min,1,v_max

// scale bar
SetDrawEnv xcoord= RespMeansB,ycoord= RespMeansL;DelayUpdate // draw line for y
DrawLine -0.05,-0.1,-0.05,0.4
SetDrawEnv xcoord= RespMeansB,ycoord= RespMeansL;DelayUpdate // draw line for x
DrawLine -0.05,-0.1,0.095,-0.1
SetDrawEnv xcoord= RespMeansB,ycoord= RespMeansL,textyjust= 2;DelayUpdate // draw text for "100 ms"
DrawText -0.1,-0.1,"100 ms"

if (tracetype == 0)
	SetDrawEnv xcoord= RespMeansB,ycoord= RespMeansL,textrot= 90;DelayUpdate
	DrawText -0.25,-0.1,"DF/F = 0.5"
endif
if (tracetype == 2)
	SetDrawEnv xcoord= RespMeansB,ycoord= RespMeansL,textrot= 90;DelayUpdate
	DrawText -0.25,-0.1,"F's\\S-1\\M = 0.5"
endif

//SetDrawEnv xcoord= RespMeansB,ycoord= RespMeansL,textrot= 90;DelayUpdate
//DrawText -0.2,-0.1,"DF/F = 0.5"
//get rid of axes
ModifyGraph axRGB(RespMeansL)=(65535,65535,65535),axRGB(RespMeansB)=(65535,65535,65535),tlblRGB(RespMeansL)=(65535,65535,65535),tlblRGB(RespMeansB)=(65535,65535,65535),alblRGB(RespMeansL)=(65535,65535,65535),alblRGB(RespMeansB)=(65535,65535,65535)

// move axes to top row, left column
ModifyGraph axisEnab(RespMeansL)={0.78,1},axisEnab(RespMeansB)={0,0.25} // move traces into top left third
ModifyGraph freePos(RespMeansL)={0,kwFraction},freePos(RespMeansB)={0.78,kwFraction} // mpove axes to top left third

end

// b) Mean response +/- SD side by side plot
Function SideBySide_PLot(meanMat, SDMat, tracetype) // use RespMeans_z or RespMeans_decon
wave meanMat, SDMat
variable tracetype

string MeanMatName = nameofwave(meanMat)
string SDMatName = nameofwave(SDMat)
variable i
variable nStimConds = dimsize(meanMat,1)

wave stimsnips // make stimsnips amp = 0.5
duplicate/o stimsnips,temp
variable OGamp = wavemax(temp)
stimsnips/=OGamp
stimsnips/=2
killwaves temp

// Add mean traces with SD shading to axes
for (i=0;i<nStimConds;i+=1)
	appendtograph/L=IndCondsL/B=IndiCondsB $MeanMatName[][i]; delayupdate
	string meanwavename = nameofwave(meanMat) + "#" + num2str(i+10)
	modifygraph offset($meanwavename)={i*2,0}
	ErrorBars $meanwavename SHADE= {0,0,(0,0,0,0),(0,0,0,0)},wave=($SDMatName[][i],$SDMatName[][i])
endfor

// append stimulus steps below traces, labelled with numbers
for (i=0;i<nStimConds;i+=1)
	appendtograph/L=IndCondsL/B=IndiCondsB StimSnips[][i]
	string stimsnipname = nameofwave(StimSnips) + "#" + num2str(i)
	modifygraph offset($stimsnipname)={i*2,-1}
endfor
SetDrawEnv xcoord= IndiCondsB,ycoord= abs,textrgb= (0,0,0);DelayUpdate // Add numbers to contrast steps
DrawText 0,130,"-100 %"
SetDrawEnv xcoord= IndiCondsB,ycoord= abs,textrgb= (0,0,0);DelayUpdate
DrawText 2,130,"-50 %"
SetDrawEnv xcoord= IndiCondsB,ycoord= abs,textrgb= (0,0,0);DelayUpdate
DrawText 4,130,"-30 %"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
SetDrawEnv xcoord= IndiCondsB,ycoord= abs,textrgb= (0,0,0);DelayUpdate
DrawText 6,130,"-20 %"
SetDrawEnv xcoord= IndiCondsB,ycoord= abs,textrgb= (0,0,0);DelayUpdate
DrawText 8,130,"-10 %"
SetDrawEnv xcoord= IndiCondsB,ycoord= abs,textrgb= (0,0,0);DelayUpdate
DrawText 10.5,130,"10 %"
SetDrawEnv xcoord= IndiCondsB,ycoord= abs,textrgb= (0,0,0);DelayUpdate
DrawText 12.5,130,"20 %"
SetDrawEnv xcoord= IndiCondsB,ycoord= abs,textrgb= (0,0,0);DelayUpdate
DrawText 14.5,130,"30 %"
SetDrawEnv xcoord= IndiCondsB,ycoord= abs,textrgb= (0,0,0);DelayUpdate
DrawText 16.5,130,"50 %"
SetDrawEnv xcoord= IndiCondsB,ycoord= abs,textrgb= (0,0,0);DelayUpdate
DrawText 18.5,130,"100 %"

//add a scalebar for DF/F = 1 and time = 1 s
SetDrawEnv xcoord= IndiCondsB,ycoord= IndCondsL;DelayUpdate // add y line
DrawLine -0.5,-0.5,-0.5,0.5
SetDrawEnv xcoord= IndiCondsB,ycoord= IndCondsL;DelayUpdate // add x line
DrawLine -0.5,-0.5,0.5,-0.5
SetDrawEnv xcoord= IndiCondsB,ycoord= IndCondsL,textyjust= 2;DelayUpdate // add label "1 s"
DrawText -0.5,-0.5,"1 s"

SetDrawEnv xcoord= RespMeansB,ycoord= RespMeansL,dash= 1;DelayUpdate // add dashed baseline
DrawLine 0,0,1.5,0

if (tracetype == 0)
	SetDrawEnv xcoord= IndiCondsB,ycoord= IndCondsL,textxjust= 2,textrot= 90;DelayUpdate // add "DF/F = 0.5"
	DrawText -0.5,-0.5,"DF/F = 0.5"
endif
if (tracetype == 2)
	SetDrawEnv xcoord= IndiCondsB,ycoord= IndCondsL,textxjust= 2,textrot= 90;DelayUpdate // add "DF/F = 0.5"
	DrawText -0.5,-0.5,"F's\\S-1\\M = 0.5"
endif

//SetDrawEnv xcoord= IndiCondsB,ycoord= IndCondsL,textxjust= 2,textrot= 90;DelayUpdate // add "DF/F = 0.5"
//DrawText -0.5,-0.5,"DF/F = 0.5"

ModifyGraph axRGB(IndCondsL)=(65535,65535,65535),axRGB(IndiCondsB)=(65535,65535,65535),tlblRGB(IndCondsL)=(65535,65535,65535),tlblRGB(IndiCondsB)=(65535,65535,65535),alblRGB(IndCondsL)=(65535,65535,65535),alblRGB(IndiCondsB)=(65535,65535,65535)

// add dashed line at zero
SetDrawEnv xcoord= IndiCondsB,ycoord= IndCondsL,dash= 3;DelayUpdate
DrawLine 0,0,19.5,0

//make traces black
ModifyGraph rgb=(0,0,0)

// move axes to top row, middle and right column
ModifyGraph axisEnab(IndCondsL)={0.78,1}
ModifyGraph axisEnab(IndiCondsB)={0.35,0.95},freePos(IndCondsL)={0.35,kwFraction},freePos(IndiCondsB)={0.78,kwFraction}

end

// c) Response amplitudes - transient, sustained, rebound

Function ResponseAmplitudes_plot(Trans, Sust, Rebound, tracetype) // use (AmpsTransient_Mean, AmpsSustained_Mean, AmpsRebound_Mean) or (AmpsTransient_decon_mean, AmpsSustained_decon_mean, AmpsRebound_decon_mean)
wave Trans, Sust, Rebound
variable tracetype
wave stimconds

// plot Transient, Sustained, and Rebound amplitudes as a function of stimulus condition

string TransMean = nameOfWave(trans)
variable Tnamelen = strlen(TransMean)-5
string TransBasename = Transmean[0,Tnamelen]
string TransSD = TransBasename + "SD"
appendtograph/L=ampsL/B=amps_B $TransMean vs stimconds
ErrorBars $TransMean Y,wave=($TransSD, $TransSD)

string SustMean = nameOfWave(Sust)
variable Snamelen = strlen(SustMean)-5
string SustBasename = Sustmean[0,Snamelen]
string SustSD = SustBasename + "SD"
appendtograph/L=ampsL/B=amps_B $SustMean vs stimconds
ErrorBars $SustMean Y,wave=($SustSD, $SustSD)

string ReboundMean = nameOfWave(Rebound)
variable Rnamelen = strlen(ReboundMean)-5
string ReboundBasename = Reboundmean[0,Rnamelen]
string ReboundSD = ReboundBasename + "SD"
appendtograph/L=ampsL/B=amps_B $ReboundMean vs stimconds
ErrorBars $ReboundMean Y,wave=($ReboundSD, $ReboundSD)

SetAxis/A/N=1 ampsL // round axes to "nice" numbers
ModifyGraph lblPos(ampsL)=50,lblPos(amps_B)=40;DelayUpdate // label axes

if (tracetype == 0)
	Label ampsL "Resp. amplitude (DF/F)";DelayUpdate
	Label amps_B "Contrast step from mean light level (%)"
endif
if (tracetype == 2)
	Label ampsL "Resp. amplitude (F's\\S-1\\M)";DelayUpdate
	Label amps_B "Contrast step from mean light level (%)"
endif

ModifyGraph rgb($ReboundMean)=(65535,0,0),rgb($TransMean)=(3,52428,1), rgb($SustMean)=(0,0,0) // change colour of traces

// add zero line
ModifyGraph zero(ampsL)=2,gridEnab(ampsL)={0,0.25}
Modifygraph zero(amps_B)=2,gridEnab(amps_B)={0.42,0.64}
// move axes to middle row, first column
ModifyGraph axisEnab(ampsL)={0.42,0.64},axisEnab(amps_B)={0,0.25},freePos(ampsL)={0,kwFraction},freePos(amps_B)={0.42,kwFraction}

end

// d) Temporal jitter. SD in time to half peak as a funciton of stimulus condition.
Function TemporalJitter_Plot(w) // use (TJ_TtoHP_SD) or (TJ_decon_TtoHP_SD)
wave w
wave stimconds, RespSnips_z

appendtograph/L=TemporalJitterL/B=TemporalJitterB w vs stimconds // plot amplitudes data
SetAxis/A/N=1 TemporalJitterL
ModifyGraph lblPos(TemporalJitterL)=50,lblPos(TemporalJitterB)=40;DelayUpdate // label axes
Label TemporalJitterL "Temporal Jitter (ms)";DelayUpdate
Label TemporalJitterB "Contrast step from mean light level (%)"
string TJwavename = nameofwave(w)
ModifyGraph rgb($TJwavename)=(0,0,0) // make trace black
// move plot and axes to middle row, middle column
ModifyGraph zero(TemporalJitterB)=2,axisEnab(TemporalJitterL)={0.42,0.64},axisEnab(TemporalJitterB)={0.35,0.6},gridEnab(TemporalJitterB)={0.42,0.64},freePos(TemporalJitterL)={0.35,kwFraction},freePos(TemporalJitterB)={0.42,kwFraction}
end

// e) Adaption index
Function AdaptionIndex_plot(Snips, Means, AImean, AISD, tracetype) // use (RespSnips_z, RespMeans_z, AdaptionIndex_mean, ADaptionIndex_SD) or (RespSnips_decon, RespMeans_decon, AdaptionIndex_decon_mean, AdaptionIndex_decon_SD)
wave snips, means, AImean, AISD
variable tracetype
variable i

for (i=0;i<10;i+=1)
	appendtograph/L=AI_L/B=AI_B snips[][i][0] //append repsonses to each stimulus iteration (in black)
	string snipsname = nameofWave(snips) + "#" + num2str(i)
	modifygraph rgb($snipsname)=(0,0,0)
endfor
appendtograph/L=AI_L/B=AI_B means[][0] // append the mean in red

SetDrawEnv xcoord= AI_B,ycoord= AI_L,dash= 1;DelayUpdate
DrawLine 0,0,1.5,0

ModifyGraph lblPos(AI_L)=50,lblPos(AI_B)=40;DelayUpdate
Label AI_L "DF/F";DelayUpdate
Label AI_B "Time (ms)"

duplicate/o/r=[][][0] snips, temp
variable snipmin = wavemin(temp)
killwaves temp

wave stimsnips
appendtograph/L=AI_L/B=AI_B stimsnips[][0]
ModifyGraph rgb(StimSnips#10)=(0,0,0),offset(StimSnips#10)={0,-1}

string AItext
AItext = "Adaption index: " + num2str(AImean[0]) + " +/-" + num2str(AIsd[0])
SetDrawEnv textyjust=2,xcoord= AI_B,ycoord= AI_L;DelayUpdate
DrawText -0.05,snipmin-0.7,AItext

SetDrawEnv xcoord= AI_B,ycoord= AI_L;DelayUpdate // add line for y scale
DrawLine -0.05,snipmin,-0.05,snipmin+0.5
SetDrawEnv xcoord= AI_B,ycoord= AI_L;DelayUpdate // add line for x scale
DrawLine -0.05,snipmin,0.095,snipmin
SetDrawEnv xcoord= AI_B,ycoord= AI_L,textyjust= 2;DelayUpdate // add text "100 ms"
DrawText -0.05,snipmin,"100 ms"

if (tracetype == 0)
	SetDrawEnv xcoord= AI_B,ycoord= AI_L,textxjust= 2,textrot= 90;DelayUpdate // add text "DF/F = 0.5"
	DrawText -0.05,snipmin,"DF/F = 0.5"
endif
if (tracetype == 2)
	SetDrawEnv xcoord= AI_B,ycoord= AI_L,textxjust= 2,textrot= 90;DelayUpdate // add text "F's-1 = 0.5"
	DrawText -0.05,snipmin,"F's\\S-1\\M = 0.5"
endif

//max axes white
ModifyGraph axRGB(AI_L)=(65535,65535,65535),axRGB(AI_B)=(65535,65535,65535),tlblRGB(AI_L)=(65535,65535,65535),tlblRGB(AI_B)=(65535,65535,65535),alblRGB(AI_L)=(65535,65535,65535),alblRGB(AI_B)=(65535,65535,65535)
//move plot and axes to middle row, right column
ModifyGraph axisEnab(AI_L)={0.42,0.64},axisEnab(AI_B)={0.7,0.95},freePos(AI_L)={0.7,kwFraction},freePos(AI_B)={0.42,kwFraction}

end

// f) Dark-light index
Function DLi_Plot(DLiMean, DLiSD, DLiVal) // use (DLi_respAUC_mean_0X, DLi_respAUC_SD_0X, DLi_value) or (DLi_decon_respAUC_mean_0X, DLi_decon_respAUC_SD_0X, Dli_decon_Value)

wave DLiMean, DLiSD, DLiVal
wave stimConds_0X

string meanwavename = nameOfWave(DLiMean)
string SDwavename = nameofwave(DLiSD)
string DLiValuename = nameOfWave(DLiVal)

appendtograph/L=DLi_L/B=DLi_B DLiMean vs stimConds_0X
ErrorBars $meanwavename Y,wave=($SDwavename,$SDwavename)
SetAxis/A/N=1 DLi_L
ModifyGraph lblPos(DLi_L)=50,lblPos(DLi_B)=40;DelayUpdate
Label DLi_L "AUC (df/f/s)";DelayUpdate
Label DLi_B "Contrast step from mean light level (%)"

ModifyGraph mode($meanwavename)=7,usePlusRGB($meanwavename)=1,hbFill($meanwavename)=2,rgb($meanwavename)=(0,0,0),plusRGB($meanwavename)=(0,0,0,16384)
ModifyGraph useNegRGB($meanwavename)=1,negRGB($meanwavename)=(0,0,0,16384) // fill lines to zero

ModifyGraph zero(DLi_L)=2,zero(DLi_B)=2,gridEnab(DLi_L)={0,0.25},gridEnab(DLi_B)={0,0.22} // Add zero lines

variable DLipeak
make/o/n=(11) DLi_plus_SD
DLi_plus_SD= DLiMean + DLiSD
wavestats/q DLi_plus_SD
DLipeak = v_max
killwaves DLi_plus_SD
string DLitext
DLitext = "DLi: " + num2str(DLiVal[0])
SetDrawEnv xcoord= DLi_B,ycoord= DLi_L;DelayUpdate
DrawText -90,DLipeak,DLitext
//move plot and axes to bottom row, left column
ModifyGraph axisEnab(DLi_L)={0,0.22},axisEnab(DLi_B)={0,0.25},freePos(DLi_L)={0,kwFraction},freePos(DLi_B)={0,kwFraction}

end

// g) Baseline. Plot shifted traces with baseline label.
Function Baseline_Plot(Meanresps, bLine, tracetype) // use (RespMeans_z, Baseline) or (RespMeans_decon, baseline_decon)
wave Meanresps, bLine
variable tracetype
variable i
variable nStimConds = dimsize(Meanresps,1)

for (i=0;i<nStimConds;i+=1)
	appendtograph/L=Basleine_L/B=Basleine_B Meanresps[][i]
	string MeanRespsName = nameOfWave(MeanResps) + "#" + num2str(i+21)
	Modifygraph rgb($MeanRespsName) = (0,0,0)
endfor

variable respmax = wavemax(MeanResps)
variable respmin = wavemin(Meanresps)


SetDrawEnv xcoord= Basleine_B,ycoord= Basleine_L;DelayUpdate // add dotted line to show max of dynamic range
SetDrawEnv dash= 1,linefgc= (0,0,65535)
DrawLine 0,respmax,1.5,respmax
SetDrawEnv xcoord= Basleine_B,ycoord= Basleine_L;DelayUpdate // add dotted line to show min of dynamic range
SetDrawEnv dash= 1,linefgc= (0,0,65535)
DrawLine 0,respmin,1.5,respmin
SetDrawEnv xcoord= Basleine_B,ycoord= Basleine_L;DelayUpdate // add dotted line to baseline
SetDrawEnv dash= 2,linethick=2,linefgc= (65535,0,0)
DrawLine 0,0,1.5,0

SetDrawEnv xcoord= Basleine_B,ycoord= Basleine_L,textyjust= 2;DelayUpdate // label baseline value
string baselineval = num2str(bline[0])
DrawText 0.01,respmax,"Baseline =\r " + baselineval

// make traces black
//ModifyGraph rgb(RespMeans_z#21)=(0,0,0),rgb(RespMeans_z#22)=(0,0,0),rgb(RespMeans_z#23)=(0,0,0),rgb(RespMeans_z#24)=(0,0,0),rgb(RespMeans_z#25)=(0,0,0),rgb(RespMeans_z#26)=(0,0,0),rgb(RespMeans_z#27)=(0,0,0),rgb(RespMeans_z#28)=(0,0,0),rgb(RespMeans_z#29)=(0,0,0)
//ModifyGraph rgb(RespMeans_z#30)=(0,0,0)

// add scale bars
SetDrawEnv xcoord= Basleine_B,ycoord= Basleine_L;DelayUpdate //draw line for y scale
DrawLine -0.05,respmin,-0.05,respmin+0.5
SetDrawEnv xcoord= Basleine_B,ycoord= Basleine_L;DelayUpdate //draw line for x scale
DrawLine -0.05,respmin,0.095,respmin
SetDrawEnv xcoord= Basleine_B,ycoord= Basleine_L,textyjust= 2;DelayUpdate // add "100 ms" scale text
DrawText -0.05,respmin,"100 ms"

if (tracetype == 0)
	SetDrawEnv xcoord= Basleine_B,ycoord= Basleine_L,textxjust= 2,textrot= 90;DelayUpdate // add "DF/F = 0.5 scale
	DrawText -0.05,respmin,"DF/F = 0.5"
endif
if (tracetype == 2)
	SetDrawEnv xcoord= Basleine_B,ycoord= Basleine_L,textxjust= 2,textrot= 90;DelayUpdate // add "DF/F = 0.5 scale
	DrawText -0.05,respmin,"F's\\S-1\\M = 0.5"
endif
//make axes white
ModifyGraph axRGB(Basleine_L)=(65535,65535,65535),axRGB(Basleine_B)=(65535,65535,65535),tlblRGB(Basleine_L)=(65535,65535,65535),tlblRGB(Basleine_B)=(65535,65535,65535),alblRGB(Basleine_L)=(65535,65535,65535),alblRGB(Basleine_B)=(65535,65535,65535)
// move plots and axes to bottom row, middle colum
ModifyGraph axisEnab(Basleine_L)={0,0.22},axisEnab(Basleine_B)={0.35,0.6},freePos(Basleine_L)={0.35,kwFraction},freePos(Basleine_B)={0,kwFraction}

end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function AddLegend_Plot(inputtype)
variable inputtype

if (inputtype == 0)
	Legend/C/N=text0/J/F=0/A=MC/X=-30.00/Y=15.00 "\\Z08\\s(AmpsTrans_mean) Transient\r\\s(AmpsSust_mean) Sustained\r\\s(AmpsReb_mean) Rebound"
endif

if (inputtype == 2)
	Legend/C/N=text0/J/F=0/A=MC/X=-30.00/Y=15.00 "\\Z08\r\\s(D_AmpsTrans_mean) Transient\r\\s(D_AmpsSust_mean) Sustained\r\\s(D_AmpsReb_mean) Rebound"
endif

// Adding titles to each plot

SetDrawEnv xcoord= abs,ycoord= abs,fstyle= 1,fsize= 11;DelayUpdate
DrawText 50,15,"(A) Mean responses to each stimulus condition"

SetDrawEnv xcoord= abs,ycoord= abs,fstyle= 1,fsize= 11;DelayUpdate
DrawText 330,15,"(B) Responses to each stimulus condition (mean +/- SD)"

SetDrawEnv xcoord= abs,ycoord= abs,fstyle= 1,fsize= 11;DelayUpdate
DrawText 50,160,"(C) Response amplitudes"

SetDrawEnv xcoord= abs,ycoord= abs,fstyle= 1,fsize= 11;DelayUpdate
DrawText 330,160,"(D) Temporal jitter (SD)"

SetDrawEnv xcoord= abs,ycoord= abs,fstyle= 1,fsize= 11;DelayUpdate
DrawText 560,160,"(E) Adaption index: Response to 100% off step"

SetDrawEnv xcoord= abs,ycoord= abs,fstyle= 1,fsize= 11;DelayUpdate
DrawText 50,335.5,"(F) Dark-light index"

SetDrawEnv xcoord= abs,ycoord= abs,fstyle= 1,fsize= 11;DelayUpdate
DrawText 330,332.5,"(G) Baseline glutamate release"

end