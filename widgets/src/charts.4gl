
#+ Simple Charting Demo
#+ $Id: charts.4gl 181 2010-01-11 10:51:19Z  $

--------------------------------------------------------------------------------
-- Draw pie chart of the passed data.
FUNCTION pie_chart(key,y,x,w,h,f1,l1,f2,l2,f3,l3,f4,l4,f5,l5,f6,l6)

	DEFINE y,x,w,h INTEGER
	DEFINE f1,f2,f3,f4,f5,f6 FLOAT
	DEFINE lb,l1,l2,l3,l4,l5,l6 CHAR(20)
	DEFINE cnt,offset, key,bars, gap, keyh, keyoff INTEGER
	DEFINE af,af1,af2,af3,af4,af5,af6 FLOAT
	DEFINE ret INTEGER
	DEFINE tot FLOAT

	LET offset = 10
	LET gap = 10
	LET bars = 6
	LET keyh = 900
	LET keyoff = (1000-offset) - key

	LET tot = f1 + f2 + f3 + f4 + f5 + f6
	LET af1 = (( 360 / tot ) * f1 ) + .5
	LET af2 = (( 360 / tot ) * f2 ) + .5
	LET af3 = (( 360 / tot ) * f3 ) + .5
	LET af4 = (( 360 / tot ) * f4 ) + .5
	LET af5 = (( 360 / tot ) * f5 ) + .5
	LET af6 = (( 360 / tot ) * f6 ) + .5

	LET tot = af1 + af2 + af3 + af4 + af5 + af6
	
	CALL drawfillcolor("white")
	CALL drawrectangle (y,x,h,w) RETURNING ret
	CALL drawlinewidth(1)
	CALL drawanchor("left")

	LET y = y + offset
	LET x = x + offset
	LET w = w - (( offset * 2 ) + key)
	LET h = h - ( offset * 2 )
 	LET y = y + ( h - offset )

	FOR cnt = 1 TO bars
		CASE cnt
			WHEN 1 
				LET af = af1
				LET lb = l1
				LET h = 0
				CALL drawfillcolor("red")
			WHEN 2 
				LET af = af2
				LET lb = l2
				LET h = af1
				CALL drawfillcolor("blue")
			WHEN 3 
				LET af = af3
				LET lb = l3
				LET h = h + af2
				CALL drawfillcolor("green")
			WHEN 4 
				LET af = af4
				LET lb = l4
				LET h = h + af3
				CALL drawfillcolor("cyan")
			WHEN 5 
				LET af = af5
				LET lb = l5
				LET h = h + af4
				CALL drawfillcolor("magenta")
			WHEN 6
				LET af = af6
				LET lb = l6
				LET h = h + af5
				CALL drawfillcolor("yellow")
		END CASE

		IF af > 0 THEN
			CALL drawarc(y,x,w,h,af) RETURNING ret
			IF key > 0 THEN 
				CALL drawtext(keyh,keyoff,lb) RETURNING ret 
				CALL drawrectangle(keyh-25,keyoff,25,key-gap) RETURNING ret
				LET keyh = keyh - 100
			END IF
		END IF
	END FOR

	DISPLAY "Finished."

END FUNCTION
--------------------------------------------------------------------------------
-- Draw bar chart of the passed data.
FUNCTION bar_chart(key,y,x,w,h,f1,l1,f2,l2,f3,l3,f4,l4,f5,l5,f6,l6)

	DEFINE y,x,w,h INTEGER
	DEFINE f1,f2,f3,f4,f5,f6 FLOAT
	DEFINE lb,l1,l2,l3,l4,l5,l6 CHAR(20)
	DEFINE cnt,offset,gap,bars,key,keyoff,keyh INTEGER
	DEFINE af,af1,af2,af3,af4,af5,af6 FLOAT
	DEFINE ret INTEGER
	DEFINE mx FLOAT

	LET offset = 15
	LET gap = 20
	LET bars = 6
	LET keyh = 900
	LET keyoff = (1000-offset) - key

	CALL drawfillcolor("white")
	CALL drawrectangle(y,x,h,w) RETURNING ret
	CALL drawlinewidth(1)

	LET y = offset + 10
	LET x = offset + 10
	LET w = ((1000-((offset*2)+key+gap)) / bars ) - gap
	LET h = 1000 - ( offset * 6 )

	LET mx = f1
	IF f2 > mx THEN LET mx = f2 END IF
	IF f3 > mx THEN LET mx = f3 END IF
	IF f4 > mx THEN LET mx = f4 END IF
	IF f5 > mx THEN LET mx = f5 END IF
	IF f6 > mx THEN LET mx = f6 END IF
	DISPLAY "y:",y USING "##&", " x:",x USING "##&", " ky:",key USING "##&"
	DISPLAY "h:",h USING "##&", " w:",w USING "##&", " mx:",mx USING "###&"

	LET af1 = ( h / mx ) * f1
	LET af2 = ( h / mx ) * f2
	LET af3 = ( h / mx ) * f3
	LET af4 = ( h / mx ) * f4
	LET af5 = ( h / mx ) * f5
	LET af6 = ( h / mx ) * f6

	CALL drawanchor("left")
	
	FOR cnt = 1 TO bars
		CASE cnt
			WHEN 1 
				LET af = af1
				LET lb = l1
				CALL drawfillcolor("red")
			WHEN 2 
				LET af = af2
				LET lb = l2
				CALL drawfillcolor("blue")
			WHEN 3 
				LET af = af3
				LET lb = l3
				CALL drawfillcolor("green")
			WHEN 4 
				LET af = af4
				LET lb = l4
				CALL drawfillcolor("cyan")
			WHEN 5 
				LET af = af5
				LET lb = l5
				CALL drawfillcolor("magenta")
			WHEN 6
				LET af = af6
				LET lb = l6
				CALL drawfillcolor("yellow")
		END CASE

		IF af > 0 THEN
			CALL drawrectangle(y,x,y+af,w) RETURNING ret
			IF key > 0 THEN 
				CALL drawtext(keyh,keyoff,lb) RETURNING ret 
				CALL drawrectangle(keyh-25,keyoff,25,key-gap) RETURNING ret
				LET keyh = keyh - 100
			END IF
			LET x = x + w + gap
		END IF
	END FOR

	DISPLAY "Finished."

END FUNCTION
--------------------------------------------------------------------------------
