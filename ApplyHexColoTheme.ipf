#pragma rtGlobals=3		// Use modern global access method and strict wave access.
Function HexColor2Igor()
	make/O/T/n=1 colortext
	
	edit/N=colortableinput colortext 
	NewPanel /K=2 /W=(187,368,437,531) as "Pause for Cursor" 
	DoWindow/C tmp_Pauseforedit 
	AutoPositionWindow/E/M=1
	DrawText 21,20,"Edit colortext"
	Button button0,pos={80,58},size={92,20},title="Continue" ,proc=editcolor_ContButtonProc
	PauseForUser tmp_Pauseforedit,colortableinput
	
	variable num_trs = numpnts(colortext)
	make/O/n=(num_trs,3) colorindex
	variable i=0
	variable tellpoundsignexit 
	do
		tellpoundsignexit = cmpstr((colortext[i])[0], "#")
		if (tellpoundsignexit == 0)
			colortext[i] = (colortext[i])[1,6]
		endif	
		colorindex[i][0] = str2num("0x" + ((colortext[i])[0,1])) *257
		colorindex[i][1] = str2num("0x" + ((colortext[i])[2,3])) *257
		colorindex[i][2] = str2num("0x" + ((colortext[i])[4,5])) *257
		i +=1
	while(i < num_trs)	
	
END

Function editcolor_ContButtonProc(ctrlName) :ButtonControl
	String ctrlName
	DoWindow/K tmp_Pauseforedit
	DoWindow/K colortableinput
	PauseForUser/C tmp_Pauseforedit, colortableinput
END

Function applyHexColor2Igor()
	wave colorindex
	String Traceslist = TraceNameList("", ";", 1)
	if (numpnts(colorindex) != ItemsInList(Traceslist))
		print "Color Theme does not match trace numbers!"
	endif	
	String TraceName
	Variable index = 0
   do
      traceName = StringFromList(index, Traceslist)
      if (strlen(traceName) == 0)
         break          // No more traces.
      endif
      modifygraph rgb($traceName) = (colorindex[index](0), colorindex[index](1),colorindex[index](2))
      index += 1
	while(1) 

END	
Menu "Graph"
	"Input Color Theme", HexColor2Igor();
	"Apply Color Theme", applyHexColor2Igor();
END	
