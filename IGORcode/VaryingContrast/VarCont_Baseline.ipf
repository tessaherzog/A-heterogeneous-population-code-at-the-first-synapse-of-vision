#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


// calculate the dynamic range of the cone
// calculate where glutamate release at mid light level sits within the dynamic range

Function VarCont_Baseline(w, tracetype) // use VarCont_Baseline(RespMeans,0)
wave w
variable tracetype

make/o/n=(1) Bline_MaxAmp = wavemax(w)
make/o/n=(1) Bline_MinAmp = wavemin(w)
make/o/n=(1) Bline_DynRange = Bline_MaxAmp[0] - Bline_MinAmp[0]

duplicate/o Bline_MaxAmp, Bline_MaxAmp_nrm // normalise min and max to make range = 1
Bline_MaxAmp_nrm/=Bline_DynRange
duplicate/o Bline_MinAmp, Bline_MinAmp_nrm
Bline_MinAmp_nrm/=Bline_DynRange

duplicate/o Bline_MinAmp_nrm, Bline
Bline*=-1

killwaves Bline_MaxAmp_nrm, Bline_MinAmp_nrm

if (tracetype == 0)
	duplicate/o Bline_MaxAmp, Baseline_MaxAmp
	duplicate/o Bline_MinAmp, Baseline_MinAmp
	duplicate/o Bline_DynRange, Baseline_DynRange
	duplicate/o Bline, Baseline_Value
	killwaves Bline_MaxAmp, Bline_MinAmp, Bline_DynRange, Bline
endif

if (tracetype == 2)
	duplicate/o Bline_MaxAmp, D_Baseline_MaxAmp
	duplicate/o Bline_MinAmp, D_Baseline_MinAmp
	duplicate/o Bline_DynRange, D_Baseline_DynRange
	duplicate/o Bline, D_Baseline_Value
	killwaves Bline_MaxAmp, Bline_MinAmp, Bline_DynRange, Bline
endif

end
