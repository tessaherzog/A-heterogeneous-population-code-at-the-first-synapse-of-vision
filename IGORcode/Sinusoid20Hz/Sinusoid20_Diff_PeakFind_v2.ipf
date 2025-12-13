Fbest#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function PeakAnal_20Hz(w)
wave w

duplicate/o w, traceToDiff
smooth 40, traceToDiff // smooth decon trace before differentiation
Differentiate traceToDiff/D=Trace_Decon_DIF
SetScale/P y 0,1,"", Trace_Decon_DIF
killwaves traceToDiff

// get threshold for detecting peaks in the differentiated trace (mean + SD during "grey")
//duplicate/o/r=[7000,8000] Trace_Decon_DIF,Trace_Decon_DIF_greySnip
//wavestats/q Trace_Decon_DIF_greySnip
//variable peakfind_Threshold = v_avg + v_sdev

variable peakfind_Threshold = 0 // threshold set to zero for peak finding in differentiated trace (threshold later on)

killwindow/z Histplot // kill plots to stop replotting
killwindow/z TracePeakPlot

variable nF = Dimsize(Trace_Decon_DIF,0)
variable maxpeaks = 1000 // max number of peaks to be detected in the trace (30s of 20 Hz stim give 600 stim its). 
variable Frameduration = 0.001
variable smoothVal = 40

make/o/n=(maxpeaks) DiffTrace_Peak_xloc = NaN // store X and Y positions of detected peaks in differential
make/o/n=(maxpeaks) DiffTrace_Peak_Amp = NaN
Make/o/N=(maxPeaks) DiffTrace_Peak_xlocpnt= NaN, DiffTrace_Peak_ylocpnt= NaN    
make/o/n=(nF) Currenttrace = Trace_Decon_DIF[p]

//if (smoothVal>0) // smooth input trace by "smoothVal" value // smoothing moved BEFORE diff. instead of after
//	Smooth smoothVal, Currenttrace
//endif

Variable peaksFound=0 // find the peaks in the differential
Variable startP=0
Variable endP= DimSize(Currenttrace,0)-1
do
    FindPeak/I/M=(peakfind_Threshold)/P/Q/R=[startP,endP] Currenttrace
    // FindPeak outputs are V_Flag, V_PeakLoc, V_LeadingEdgeLoc,
    // V_TrailingEdgeLoc, V_PeakVal, and V_PeakWidth.
    
    if( V_Flag != 0 ) // if no peaks were found, exit do
        break
    endif
    DiffTrace_Peak_xlocpnt[peaksFound]=pnt2x(Currenttrace,V_PeakLoc) // save x position (time) of detected peak on differentiated trace.
    DiffTrace_Peak_ylocpnt[peaksFound]=V_PeakVal // save y position (amp) of detected peak on differentiated trace.
    peaksFound += 1
    
    if( V_TrailingEdgeLoc > 45000) // stop detecting peaks after 45 s in the trace (stimulus period stops at 38 s)
        break
    endif
    
    startP= V_TrailingEdgeLoc+1 // start looking again for peaks in the trace after the trailing edge of the detected peak has gone below threshold again
while( peaksFound < maxPeaks )
	DiffTrace_Peak_xloc[]=DiffTrace_Peak_xlocpnt[p] * FrameDuration // wave of peak times in seconds (not points)
DiffTrace_Peak_Amp[]=DiffTrace_Peak_ylocpnt[p]
killwaves DiffTrace_Peak_ylocpnt

Differentiate DiffTrace_Peak_xloc/D=DiffTrace_Peak_xloc_DIF;DelayUpdate
Make/N=100/O DiffTrace_Peak_xloc_DIF_Hist;DelayUpdate
Histogram/B=1 DiffTrace_Peak_xloc_DIF,DiffTrace_Peak_xloc_DIF_Hist;DelayUpdate
display/k=1/n=HistPlot DiffTrace_Peak_xloc_DIF_Hist

display/k=1/n=TracePeakPlot/L=L_Trace_decon w // display the decon trace and the detected peaks
ModifyGraph rgb=(0,0,0)
appendtograph/L=L_Trace_Diff Trace_Decon_DIF
appendtograph/L=L_Trace_Diff DiffTrace_Peak_Amp vs DiffTrace_Peak_xloc
ModifyGraph mode(DiffTrace_Peak_Amp)=3,marker(DiffTrace_Peak_Amp)=19,rgb(DiffTrace_Peak_Amp)=(0,0,65535), msize(DiffTrace_Peak_Amp)=2
SetAxis bottom 30,31
killwaves Currenttrace
ModifyGraph lblMargin(bottom)=5,lblPos(L_Trace_decon)=50,lblPos(L_Trace_Diff)=50,axisEnab(L_Trace_decon)={0.5,1},axisEnab(bottom)={0.1,1},axisEnab(L_Trace_Diff)={0,0.5},freePos(L_Trace_decon)=-20,freePos(L_Trace_Diff)=-20;DelayUpdate
Label L_Trace_decon "Decon. trace";DelayUpdate
Label bottom "Time (s)";DelayUpdate
Label L_Trace_Diff "Diff. trace"

end