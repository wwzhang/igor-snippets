#pragma rtGlobals=3		// Use modern global access method and strict wave access.
//Provide a GUI interface to perform the following 2 groups and multiple groups statistical analysis:
//	Normality test, variance test, (paired) t-test, Cohen's D
// v 0.1  2014/09/29 two groups
// v 0.2  2015/08/20 multiple goups added
// v 0.21 2016/03/09 minor editing
#include <WaveSelectorWidget>
Function Make2WaveSelectorPanel()


	String panelName = "WaveSelectorExample"
	// figure out what to show in the Wave Selector, and make an appropriate name for the panel

			panelName+="Waves"


	if (WinType(panelName) == 7)
		// if the panel already exists, show it
		DoWindow/F $panelName
	else
		// doesn't exist, make it
		NewPanel/N=$panelName/W=(181,180,471,580) as "Statistical Analysis"
		// list box control doesn't have any attributes set on it
		ListBox ExampleWaveSelectorList,pos={9,13},size={273,241}
		// This function does all the work of making the listbox control into a
		// Wave Selector widget. Note the optional parameter that says what type of objects to
		// display in the list.
		MakeListIntoWaveSelector(panelName, "ExampleWaveSelectorList", content = WMWS_Waves)


			PopupMenu sortKind, pos={9,270},title="Sort Waves By"
			MakePopupIntoWaveSelectorSort(panelName, "ExampleWaveSelectorList", "sortKind")

		// This is an extra bonus- you can create your own function to be notified of certain events,
		// such as a change in the selection in the list.
		WS_SetNotificationProc(panelName, "ExampleWaveSelectorList", "ExtExampleNotification", isExtendedProc=1)

		// To support this demo, provide a button that displays this code
		SetDrawEnv fstyle= 1,fsize= 14;DrawText 2,320,"--- Two Groups ---"
		
		Button Gr2Comp,pos={9,325},size={90,20},proc=gr2stat_0,title="2 Group"
		Button GrPairComp,pos={105,325},size={90,20},proc=gr2stat_1,title="Pair"
		Button KSonly, pos={200,325},size={80,20},proc=ksonly,title="K-S"

		SetDrawEnv fstyle= 1,fsize= 14;DrawText 2,370, "--- Multiple Groups ---"
		Button MultiComp,pos={9,375},size={90,20},proc=ANOVA_st,title="ANOVA"
		Button DunnettComp,pos={105,375},size={90,20},proc=Dunnett_st,title="Dunnett's"
		Button ScheffeComp, pos={200,375},size={80,20},proc=Tukey_st,title="TUkey"
	endif
End

Function gr2stat_0(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			comp2(1)// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0

End

Function gr2stat_1(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			comp2(3)// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0

End

Function ksonly(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			comp2(8)// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0

End

Function ANOVA_st(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			ANOVA_st_test()// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0

End

Function Dunnett_st(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			Dunnett_st_test()// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0

End

Function Tukey_st(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			Tukey_st_test()// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0

End

Function ANOVA_st_test()
	string w_sed = WS_SelectedObjectsList("Waveselectorexamplewaves","ExampleWaveSelectorList")
	print w_sed
	//use ItemsInList tell how many strings
	sn_nb();Append2SN_TS()
	variable items_st = ItemsInList(w_sed)
	variable index_st = 0, nd_xs = 0
	do
		string g_st =  StringFromList(index_st, w_sed)
		wave group_st = $g_st
		Append2SN("*" + g_st + ":\r	mean = " + num2str(mean(group_st)) + " sem = " + num2str(sqrt(variance(group_st)/numpnts(group_st))) + " n = " + num2str(numpnts(group_st)))

		statsjbtest/Q group_st
		wave W_JBResults
		variable nd_x1 = 0 
		if (W_JBResults[3] < W_JBResults[5])
			Append2SN("" + g_st + " is Normal distribution")
			nd_x1 = 0
		else
			Append2SN("" + g_st + " is not normal")
			nd_x1 = 1
		ENDIF
		nd_xs += nd_x1
		index_st += 1
	while(index_st < items_st)
	if (nd_xs > 1)
		Append2SN("Not all groups normal distributed")
	ENDIF	
	StatsVariancesTest/METH=1 /WSTR=w_sed
	wave W_statsVariancesTest
	variable nd_xs_var
		if (W_statsVariancesTest[2] < W_statsVariancesTest[3])
			Append2SN("Groups' variances same")
			nd_xs_var = 0
		else
			Append2SN("Groups' variances NOT same")
			nd_xs_var = 1
		ENDIF
	variable hs_rn = (CaptureHistoryStart())	
		if(nd_xs == 0  && nd_xs_var == 0)
			Append2SN("USE ANOVA\r" )
			StatsANOVA1Test/WSTR=w_sed
			Append2SN("" + capturehistory(hs_rn, 0))
			
		else
			Append2SN("USE Kruskal-Wallis test \r")
			StatsKWTest/WSTR=w_sed
			Append2SN("" + capturehistory(hs_rn, 0))
		ENDIF
END

Function Dunnett_st_test()
	string w_sed = WS_SelectedObjectsList("Waveselectorexamplewaves","ExampleWaveSelectorList")
	print w_sed
	Append2SN("Dunnett's Test\r")
	//TODO kill WMStatsTestResultTableDunnett Window
	//variable hs_rn = (CaptureHistoryStart()) //NO histrory output
	StatsDunnettTest/TAIL=4/T=1/SWN /WSTR=w_sed
	//Append2SN("" + capturehistory(hs_rn, 0))
END	

Function Tukey_st_test()
	string w_sed = WS_SelectedObjectsList("Waveselectorexamplewaves","ExampleWaveSelectorList")
	print w_sed
	Append2SN("Tukey test \r")
	//TODO kill WMStatsTestResultTableDunnett Window
	//variable hs_rn = (CaptureHistoryStart()) //NO histrory output
	StatsTukeyTest/T=1/SWN /WSTR=w_sed
	//Append2SN("" + capturehistory(hs_rn, 0))
END	


Function comp2(p2)
	variable p2
	string w_sed = WS_SelectedObjectsList("Waveselectorexamplewaves","ExampleWaveSelectorList")
	//use ItemsInList tell how many strings
	string x1_n = StringFromList(0, w_sed)
	string x2_n = StringFromlist(1, w_sed)
	wave x1 = $x1_n
	wave x2 = $x2_n
	sn_nb();Append2SN_TS()
	Append2SN("*" + x1_n + ":\r	mean = " + num2str(mean(x1)) + " sem = " + num2str(sqrt(variance(x1)/numpnts(x1))) + " n = " + num2str(numpnts(x1)))
	Append2SN("*" + x2_n + ":\r	mean = " + num2str(mean(x2)) + " sem = " + num2str(sqrt(variance(x2)/numpnts(x2))) + " n = " + num2str(numpnts(x2)))

	if (p2 == 1)
		Append2SN("*** Compare 2 waves ***")
		cmp2(1, x1, x2)
	elseif (p2 == 3)
		Append2SN("*** Compare paired waves ***")
		cmp2(3, x1, x2)
	elseif (p2 == 8)
		Append2SN("*** K-S TEST ***")
		cmp2(8, x1, x2)	
	ENDIF
END


Function Append2SN_TS() //Time Stamp
	Variable stampDateTime = 1 // nonzero if we want to include stamp
  	Variable tnow
   String stamp
	Notebook StatNote selection={endOfFile, endOfFile}
	tnow = datetime
	stamp = Secs2Date(tnow,0) + ", " + Secs2Time(tnow,0)
	Notebook StatNote, textRGB=(65535,0,0), text="\r" + "****" + stamp + "****\r"
	Notebook StatNote, textRGB=(0,0,0)
End

Function Append2SN(str) //Add Log
	String str
	Notebook StatNote selection={endOfFile, endOfFile}
	Notebook StatNote text= str+"\r"
End

Function sn_nb()
	if (WinType("StatNote") == 5)
		// if StatNote already exists, show it
		DoWindow/F StatNote
	else
		newnotebook /n=StatNote /F=1 as "Stat Results Note"
	ENDIF
END

Function effect_size(x1, x2)
	wave x1, x2
	variable cohen_s_d = abs(mean(x1) - mean (x2))/sqrt((variance(x1) + variance(x2))/2)
	Append2SN("*Effect Size:\r	Cohen's d = " + num2str(cohen_s_d) + " (d = 0.2, small; 0.5, medium; 0.8, large)")
END

Function cmp2(p2, x1, x2)
	variable p2
	wave x1, x2
	statsjbtest/Q x1
	wave W_JBResults
	variable nd_x1
		if (W_JBResults[3] < W_JBResults[5])
			Append2SN("x1 is Normal distribution")
			nd_x1 = 1
		else
			Append2SN("x1 is not normal")
			nd_x1 = 0
		ENDIF
	statsjbtest/Q x2
	wave W_JBResults
	variable nd_x2
		if (W_JBResults[3] < W_JBResults[5])
			Append2SN("x1 is Normal distribution")
			nd_x2 = 1
		else
			Append2SN("x1 is not normal")
			nd_x1 = 0
		ENDIF
	statsvariancestest/Q x1, x2
	wave W_statsVariancesTest
	variable nd_xs
		if (W_statsVariancesTest[2] < W_statsVariancesTest[3])
			Append2SN("x1, x2 variance same")
			nd_xs = 1
		else
			Append2SN("x1, x2 variance NOT same")
			nd_xs = 0
		ENDIF
	variable p2w_con = (nd_x1==1 && nd_x2==1 && nd_xs==1)
	variable p2_final
		if (p2 == 8)
			p2_final = p2
		else
			p2_final = p2 + p2w_con
		ENDIF	
	variable hs_rn = (CaptureHistoryStart())
	switch(p2_final)
		case 2:
			Append2SN("USE T-TEST\r" + capturehistory(hs_rn, 0) )
			statsttest x1, x2
			break
		case 1:
			Append2SN("USE K-S TEST\r" + capturehistory(hs_rn, 0))
			statskstest x1, x2
			break
		case 4:
			Append2SN("USE paired T-TEST\r" + capturehistory(hs_rn, 0))
			statsttest /PAIR x1, x2
			break
		case 3:
			Append2SN("USE Wilcoxon Signed Rank Test\r" +capturehistory(hs_rn, 0))
			StatsWilcoxonRankTest /WSRT  x1, x2
			break
		case 8:
			Append2SN("USE K-S TEST\r" + capturehistory(hs_rn, 0))
			statskstest x1, x2
			break	
	endswitch
	Append2SN(CaptureHistory(hs_rn, 1))
	effect_size(x1, x2)
END
