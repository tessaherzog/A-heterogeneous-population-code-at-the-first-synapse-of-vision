#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// Get the fraction of stimulus cycles in which a response occured.

Function FractionOfResponses(w) // use peak_Amp_perStim_Thresh
wave w

variable nStimIts = dimsize(w,0)
variable i
make/o/n=(1) ResponseRate
ResponseRate = 0

for (i=0;i<nStimIts;i+=1)
	if (numtype(W[i]) == 0) // check numtype for just a normal number (i.e. not a NaN which indicates a missed response)
		ResponseRate+=1
	endif
endfor
variable MissedStims = nStimIts - ResponseRate[0]
print num2str(MissedStims) + " stimulus phases missed."
ResponseRate/=nStimIts
ResponseRate*=100

print "Response rate = " + num2str(ResponseRate[0]) + "%"
END