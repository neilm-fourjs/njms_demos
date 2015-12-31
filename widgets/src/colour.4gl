
{ CVS Header
$Author: $
$Date: 2008-07-22 17:56:39 +0100 (Tue, 22 Jul 2008) $
$Revision: 2 $
$Source: /usr/home/test4j/cvs/all/demos/widgets/src/colour.4gl,v $
$Log: colour.4gl,v $
Revision 1.5  2007/07/12 16:43:03  test4j
*** empty log message ***

Revision 1.4  2006/07/21 11:23:08  test4j
*** empty log message ***

Revision 1.1  2005/11/17 18:14:12  test4j
*** empty log message ***

Revision 1.2  2005/05/10 14:48:12  test4j

Added cvs header.

}

FUNCTION colours(ask)

	DEFINE ask SMALLINT
	DEFINE opt SMALLINT
	DEFINE cols RECORD
		col1 CHAR(10),
		col2 CHAR(10),
		col3 CHAR(10),
		col4 CHAR(10)
	END RECORD

	OPTIONS PROMPT LINE LAST

	LET cols.col1 = "Red"
	LET cols.col2 = "Blue..."
	LET cols.col3 = "Green"
	LET cols.col4 = "Yellow"

	LET opt = 1

	WHILE opt != 0

		IF opt = 1 THEN
			DISPLAY BY NAME cols.col1 ATTRIBUTE(RED)
			DISPLAY BY NAME cols.col2 ATTRIBUTE(BLUE)
			DISPLAY BY NAME cols.col3 ATTRIBUTE(GREEN)
			DISPLAY BY NAME cols.col4 ATTRIBUTE(YELLOW)
			DISPLAY "Cyan   " TO col5 ATTRIBUTE(CYAN)
			DISPLAY "Magenta" TO col6 ATTRIBUTE(MAGENTA)
			DISPLAY "Black  " TO col7 ATTRIBUTE(BLACK)
			DISPLAY "White  " TO col8 ATTRIBUTE(WHITE)
			DISPLAY "Normal " TO clab1 ATTRIBUTE(RED)
			DISPLAY "Normal " TO clab2 ATTRIBUTE(BLUE)
			DISPLAY "Normal " TO clab3 ATTRIBUTE(GREEN)
			DISPLAY "Normal " TO clab4 ATTRIBUTE(YELLOW)
			DISPLAY "Normal " TO clab5 ATTRIBUTE(CYAN)
			DISPLAY "Normal " TO clab6 ATTRIBUTE(MAGENTA)
			DISPLAY "Normal " TO clab7 ATTRIBUTE(BLACK)
			DISPLAY "Normal " TO clab8 ATTRIBUTE(WHITE)
		END IF
		
		IF opt = 2 THEN
			DISPLAY "Red    " TO col1 ATTRIBUTE(UNDERLINE,RED)
			DISPLAY "Blue   " TO col2 ATTRIBUTE(UNDERLINE,BLUE)
			DISPLAY "Green  " TO col3 ATTRIBUTE(UNDERLINE,GREEN)
			DISPLAY "Yellow " TO col4 ATTRIBUTE(UNDERLINE,YELLOW)
			DISPLAY "Cyan   " TO col5 ATTRIBUTE(UNDERLINE,CYAN)
			DISPLAY "Magenta" TO col6 ATTRIBUTE(UNDERLINE,MAGENTA)
			DISPLAY "Black  " TO col7 ATTRIBUTE(UNDERLINE,BLACK)
			DISPLAY "White  " TO col8 ATTRIBUTE(UNDERLINE,WHITE)
			DISPLAY "UNDERLINE" TO clab1 ATTRIBUTE(UNDERLINE,RED)
			DISPLAY "UNDERLINE" TO clab2 ATTRIBUTE(UNDERLINE,BLUE)
			DISPLAY "UNDERLINE" TO clab3 ATTRIBUTE(UNDERLINE,GREEN)
			DISPLAY "UNDERLINE" TO clab4 ATTRIBUTE(UNDERLINE,YELLOW)
			DISPLAY "UNDERLINE" TO clab5 ATTRIBUTE(UNDERLINE,CYAN)
			DISPLAY "UNDERLINE" TO clab6 ATTRIBUTE(UNDERLINE,MAGENTA)
			DISPLAY "UNDERLINE" TO clab7 ATTRIBUTE(UNDERLINE,BLACK)
			DISPLAY "UNDERLINE" TO clab8 ATTRIBUTE(UNDERLINE,WHITE)
		END IF
		
		IF opt = 1 THEN
			DISPLAY "Red    " TO col9 ATTRIBUTE(RED,REVERSE)
			DISPLAY "Blue   " TO col10 ATTRIBUTE(BLUE,REVERSE)
			DISPLAY "Green  " TO col11 ATTRIBUTE(GREEN,REVERSE)
			DISPLAY "Yellow " TO col12 ATTRIBUTE(YELLOW,REVERSE)
			DISPLAY "Cyan   " TO col13 ATTRIBUTE(CYAN,REVERSE)
			DISPLAY "Magenta" TO col14 ATTRIBUTE(MAGENTA,REVERSE)
			DISPLAY "Black  " TO col15 ATTRIBUTE(BLACK,REVERSE)
			DISPLAY "White  " TO col16 ATTRIBUTE(WHITE,REVERSE)
			DISPLAY "REVERSE" TO clab9 ATTRIBUTE(RED)
			DISPLAY "REVERSE" TO clab10 ATTRIBUTE(BLUE,REVERSE)
			DISPLAY "REVERSE" TO clab11 ATTRIBUTE(GREEN,REVERSE)
			DISPLAY "REVERSE" TO clab12 ATTRIBUTE(YELLOW,REVERSE)
			DISPLAY "REVERSE" TO clab13 ATTRIBUTE(CYAN,REVERSE)
			DISPLAY "REVERSE" TO clab14 ATTRIBUTE(MAGENTA,REVERSE)
			DISPLAY "REVERSE" TO clab15 ATTRIBUTE(BLACK,REVERSE)
			DISPLAY "REVERSE" TO clab16 ATTRIBUTE(WHITE,REVERSE)
		END IF
		
		IF opt = 2 THEN
			DISPLAY "Red    " TO col9 ATTRIBUTE(UNDERLINE,RED,REVERSE)
			DISPLAY "Blue   " TO col10 ATTRIBUTE(UNDERLINE,BLUE,REVERSE)
			DISPLAY "Green  " TO col11 ATTRIBUTE(UNDERLINE,GREEN,REVERSE)
			DISPLAY "Yellow " TO col12 ATTRIBUTE(UNDERLINE,YELLOW,REVERSE)
			DISPLAY "Cyan   " TO col13 ATTRIBUTE(UNDERLINE,CYAN,REVERSE)
			DISPLAY "Magenta" TO col14 ATTRIBUTE(UNDERLINE,MAGENTA,REVERSE)
			DISPLAY "Black  " TO col15 ATTRIBUTE(UNDERLINE,BLACK,REVERSE)
			DISPLAY "White  " TO col16 ATTRIBUTE(UNDERLINE,WHITE,REVERSE)
			DISPLAY "REVERSE,UNDERLINE" TO clab9 ATTRIBUTE(UNDERLINE,RED,REVERSE)
			DISPLAY "REVERSE,UNDERLINE" TO clab10 ATTRIBUTE(UNDERLINE,BLUE,REVERSE)
			DISPLAY "REVERSE,UNDERLINE" TO clab11 ATTRIBUTE(UNDERLINE,GREEN,REVERSE)
			DISPLAY "REVERSE,UNDERLINE" TO clab12 ATTRIBUTE(UNDERLINE,YELLOW,REVERSE)
			DISPLAY "REVERSE,UNDERLINE" TO clab13 ATTRIBUTE(UNDERLINE,CYAN,REVERSE)
			DISPLAY "REVERSE,UNDERLINE" TO clab14 ATTRIBUTE(UNDERLINE,MAGENTA,REVERSE)
			DISPLAY "REVERSE,UNDERLINE" TO clab15 ATTRIBUTE(UNDERLINE,BLACK,REVERSE)
			DISPLAY "REVERSE,UNDERLINE" TO clab16 ATTRIBUTE(UNDERLINE,WHITE,REVERSE)
		END IF
	
		IF ask THEN
			MENU ""
				COMMAND "Normal" "Just the colour attribute"
					LET opt = 1
					EXIT MENU
				COMMAND "Underline" "Colour & Underline attribute"
					LET opt = 2
					EXIT MENU
				COMMAND "Exit" "Return to wence you came."
					LET opt = 0
					EXIT MENU
			END MENU
		ELSE
			EXIT WHILE
		END IF

	END WHILE

END FUNCTION
