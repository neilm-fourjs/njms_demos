--------------------------------------------------------------------------------
#+ The Widgets Demo by Neil J Martin ( neilm@4js.com )
#+
#+ Changed so can run on Windows and be packaged easier, add about
#+ Added the show source code feature
#+ Added more/less to toolbar for folder page hiding + to dynamic ta
#+ Added debug and widgets.inc
#+ Change clock2 for Genero 2 to use util.math for sin/cos instead of db.
#+
#+ $Id: widgets.4gl 344 2015-08-18 11:23:17Z neilm $
--------------------------------------------------------------------------------

IMPORT util
IMPORT FGL genero_lib1

CONSTANT p_version = "$Rev: 344 $"

&include "version.inc"
&include "widgets.inc"
&include "genero_lib1.inc"

	DEFINE func CHAR(1)
	DEFINE m_answer STRING
	DEFINE norm CHAR(20)
	DEFINE normbe CHAR(50)
	DEFINE wordw CHAR(500)
	DEFINE combo CHAR(10)
	DEFINE c_year SMALLINT
	DEFINE check CHAR(1)
	DEFINE radio CHAR(1)
	DEFINE formt CHAR(10)
	DEFINE dateedit DATE
	DEFINE datetimeedit DATETIME YEAR TO SECOND
	DEFINE timeedit DATETIME HOUR TO SECOND
	DEFINE lins,slider,spinedit SMALLINT
	DEFINE dec DECIMAL(6,2)
	DEFINE chart_key INTEGER
	DEFINE chart_typ CHAR(1) 
	DEFINE sort1,sort2,sort3 SMALLINT

	TYPE t_rec RECORD
		img STRING,
		nam STRING,
		font STRING,
		val STRING
	END RECORD
	DEFINE m_imgrec DYNAMIC ARRAY OF t_rec

	DEFINE oldarr ARRAY [arrmax] OF RECORD
		arr1 CHAR(10),
		arr2 CHAR(10),
		arr3 CHAR(10)
	END RECORD

	DEFINE arr DYNAMIC ARRAY OF RECORD
		tabc1 SMALLINT,
		img STRING,
		tabc2 STRING,
		tabc3 DATE
	END RECORD

	DEFINE newarr2 DYNAMIC ARRAY OF RECORD
		tabc1 SMALLINT,
		tabc2 CHAR(20),
		tabc3 DATE,
		tabc4 CHAR(30),
		tabc5 CHAR(2),
		tabc6 CHAR(1)
	END RECORD

	DEFINE newarr3 DYNAMIC ARRAY {[arrmax]} OF RECORD
		tabc1 CHAR(4),
		tabc2 CHAR(20)
	END RECORD

	DEFINE g_win ui.Window
	DEFINE g_frm ui.Form

	DEFINE cnt SMALLINT
	DEFINE scal SMALLINT
	DEFINE g_defs STRING
	DEFINE f_n om.domNode
	DEFINE m_dbname VARCHAR(20)
--------------------------------------------------------------------------------
MAIN
	DEFINE tmp STRING
	DEFINE stat SMALLINT
	DEFINE f ui.Form

	DISPLAY p_progname," - ",p_progdesc," ",gl_verFmt(p_version)
	DISPLAY "FGLSERVER=",fgl_getEnv("FGLSERVER")
	CALL genero_lib1.gl_setInfo(p_version,p_splash, p_progicon, p_progname, p_progdesc, p_progauth)

	LET g_defs = "mydefaults"
	IF ARG_VAL(2) IS NOT NULL AND ARG_VAL(2) != " " THEN
		LET g_defs = ARG_VAL(2)
	END IF

	CALL genero_lib1.gl_init("s",g_defs,TRUE)
	GL_DBGMSG(2,"init_genero, done.")
GL_MODULE_ERROR_HANDLER
	LET m_dbname = fgl_getEnv("DBNAME")

	CLOSE WINDOW SCREEN
	GL_DBGMSG(2,"done - Close window screen.")

	LET db_opened = FALSE
	LET cwd = base.application.getProgramDir()
	LET gdcver = gl_feVer()
	LET gver = "build ",fgl_getversion()
	LET gdcip = fgl_getenv("FGLSERVER")
	IF gdcip IS NULL OR gdcip = " " THEN LET gdcip = "localhost" END IF
	GL_DBGMSG(0, "Client:"||gdcver||" On:"||gdcip )
	GL_DBGMSG(0, "Runtime:"||gver )
	GL_DBGMSG(2,"Got Versions.")

	LET tmp = fgl_getenv("SHELL") -- detect OS ( hopefully )
	GL_DBGMSG(1, "shell:"||tmp )
	GL_DBGMSG(1, "CWD:"||cwd )

--	CALL fgl_settitle(gl_progdesc||" "||gl_version)
--	GL_DBGMSG(2,"done - Settitle.")

	IF tmp = "sh.exe" OR gdcip = "localhost" THEN
		CALL fix_path()
	ELSE
		LET cwd = "/fourjs/"
	END IF
	GL_DBGMSG(2,"done - fix_path.")

	IF (ARG_VAL(1) IS NULL OR ARG_VAL(1) != "-nosplash")
	AND UPSHIFT(ui.Interface.getFrontEndName()) = "GDC" THEN
		GL_DBGMSG(4,"doing splash.")
		CALL gl_splash()
		GL_DBGMSG(4,"done splash.")
	END IF

	GL_DBGMSG(4,"before - open window.")
	OPEN WINDOW widgets WITH FORM "widgets"
	GL_DBGMSG(4,"after - open window.")
	CALL ui.interface.setImage( gl_progicon )
	CALL hide_item("Page","arrays",1)
	CALL hide_item("Page","canvas",1)
	CALL hide_item("Page","colours",1)
	CALL ui.interface.refresh()
	GL_DBGMSG(4,"after - ui.interface.refresh.")

	LET lins = FALSE
	LET scal = 100
	LET chart_key = 0
	LET chart_typ = "B"
	LET sort1 = TRUE
	LET sort2 = TRUE
	LET sort3 = TRUE
	LET dec = 12.34
	CALL arr_set()
	DISPLAY "Setting array newarr2"
	FOR cnt = 1 TO arr.getLength()
		LET oldarr[cnt].arr1 = "Item ",cnt USING "##"
		LET oldarr[cnt].arr2 = "Item ",ASCII(65+(10-cnt))
		LET oldarr[cnt].arr3 = "Dummy"
		LET arr[cnt].tabc1 = cnt
		LET arr[cnt].tabc2 = arr[cnt].img
		LET arr[cnt].tabc3 = TODAY
		LET newarr3[cnt].tabc1 = ASCII(64+cnt)
		LET newarr3[cnt].tabc2 = "Row",cnt USING "<<<"
		LET newarr2[cnt].tabc1 = cnt
		IF cnt < 15 THEN -- done to leave some NULL data in the table
			LET newarr2[cnt].tabc2 = "Row",cnt USING "<<<"
			LET newarr2[cnt].tabc3 = TODAY
			LET newarr2[cnt].tabc4 = "Hello World!"
			LET newarr2[cnt].tabc5 = "AB"
			LET newarr2[cnt].tabc6 = "Y"
		ELSE
			LET newarr2[cnt].tabc2 = NULL
			LET newarr2[cnt].tabc3 = NULL
			LET newarr2[cnt].tabc4 = NULL
			LET newarr2[cnt].tabc5 = NULL
			LET newarr2[cnt].tabc6 = NULL
		END IF
	END FOR
&ifdef genero3x
	CALL load_new_imgarr(FALSE) -- old icons
	CALL load_new_imgarr(TRUE) -- fa icons
	CALL arr.clear()
	FOR cnt = 1 TO m_imgrec.getLength()
		LET arr[cnt].img = m_imgrec[cnt].img
		LET arr[cnt].tabc1 = cnt
		LET arr[cnt].tabc2 = m_imgrec[cnt].nam||" ("||m_imgrec[cnt].val||")"
		LET arr[cnt].tabc3 = TODAY
	END FOR
&endif

	LET aniyn = FALSE

	CALL disp_form()
	GL_DBGMSG(2,"after - disp_form.")

--	DISPLAY BY NAME norm[1]

	DISPLAY "Arr:",arr.getLength()
	DISPLAY ARRAY arr TO newarr.* ATTRIBUTE(COUNT=arr.getLength())
		BEFORE DISPLAY
			EXIT DISPLAY
	END DISPLAY

	LET func = "."
	WHILE func != "Q"

		DIALOG ATTRIBUTE(UNBUFFERED)
			DISPLAY ARRAY arr TO newarr.*
			END DISPLAY
			BEFORE DIALOG
				LET f = DIALOG.getForm()
				LET f_n = f.getNode()
				CALL f.ensureElementVisible("styles")
				GL_DBGMSG(2,"Before menu")
				CALL gl_defAction("M","gl_lookup","GL Lookup","My Library Code for a dynamic lookup","find","control-l")
			COMMAND "chgstyle0"
				LET func = "0"
				EXIT DIALOG
			COMMAND "chgstyle1"
				LET func = "1"
				EXIT DIALOG
			COMMAND "chgstyle2"
				LET func = "2"
				EXIT DIALOG
			COMMAND "chgstyle3"
				LET func = "3"
				EXIT DIALOG

			COMMAND "inputs" "Do the inputs"
				LET func = "I"
				EXIT DIALOG
	
			COMMAND "inputa" "Do the inputs arrays"
				LET func = "A"
				EXIT DIALOG
	
			COMMAND "displaya" "Do the display arrays"
				LET func = "D"
				EXIT DIALOG

			COMMAND "ndialog" 
				CALL ndialog()

			COMMAND "inputa2" 
				CALL lookup1("I")

			COMMAND "webkit"
				CALL webkit()

			COMMAND "manual"
				CALL winshellexec( "d:\\temp\\genero220.pdf" ) RETURNING stat

			COMMAND "displaya2" 
				CALL lookup1("D")

			COMMAND "onidle"
				CALL onidle()

			COMMAND "dumpxml"
				CALL f_n.writeXML("form.xml")

			COMMAND "winst1"
				CALL disp_newwin("normal","Normal")
	
			COMMAND "winst2"
				CALL disp_newwin("main","Main")
	
			COMMAND "winst3"
				CALL disp_newwin("dialog","Dialog")
	
			COMMAND "winst4"
				CALL disp_newwin("naked","Naked")
	
			COMMAND "winst5"
				CALL disp_newwin("mystyle","MyStyle")
	
			COMMAND "colours"
				LET func = "c"
				EXIT DIALOG

			COMMAND "textedt"
				CALL textedit()

			COMMAND "dynamic" "Dynamic demo"
				LET func = "Y"
				EXIT DIALOG
	
			COMMAND "canvas" "See canvas demo"
				LET func = "C"
				EXIT DIALOG

			COMMAND "dynamictab" "Dynamic Table"
				CALL dyntab()

			COMMAND "Time" "See canvas demo"
				CALL clock2()

			COMMAND "Sum" "DDE some data to Excel"
				CALL excel()
	
			COMMAND "progbar" "Draw a progress bar."
				CALL gl_progBar(1,100,"Processing random data ...")
				CALL delay()
				FOR cnt = 1 TO 100
					CALL gl_progBar(2,cnt,"")
					CALL delay()
				END FOR
				CALL gl_progBar(3,0,"")
			COMMAND "progbar2" "Draw a progress bar - Doing something."
				CALL gl_progBar(1,-100,"Processing random data ...")
				CALL delay()
				FOR cnt = 1 TO 100
					CALL gl_progBar(2,cnt,"")
					CALL delay()
				END FOR
				CALL gl_progBar(3,0,"")

&ifdef genero3x
			ON TIMER 2
				LET timeedit = CURRENT
				LET datetimeedit = CURRENT
				DISPLAY BY NAME timeedit, datetimeedit
&endif

			ON ACTION url
				CALL ui.interface.frontCall("standard","shellexec","http://www.4js.com/",[tmp])

			ON ACTION splash
				CALL gl_splash()

			ON ACTION about
				CALL gl_about( gl_verFmt(gl_version) )

			ON ACTION gl_lookup
				IF NOT db_opened THEN
					MESSAGE "DB Open:",m_dbname
					TRY
						DATABASE m_dbname
						LET db_opened = TRUE
					CATCH
						CALL fgl_winMessage("Error",SFMT("Failed to open db '%1'",m_dbname),"exclamation")
						CONTINUE DIALOG
					END TRY
				END IF
&ifdef genero3x
				MENU "" ATTRIBUTES(STYLE="popup")
					COMMAND "systables2"
						LET tmp = gl_lookup3( "systables",
							"tabname,created,nrows,rowsize,(nrows*rowsize)",
							"Name,Created,Rows,RowSize,Total",
							"tabid>99",
							"tabname")
					COMMAND "Stock"
						LET tmp = gl_lookup3( "stock",
							"stock_code,description,stock_cat,pack_flag,supp_code,price,cost,physical_stock,allocated_stock,free_stock",
							"Code,Description,Cat,Pack,Supplier,Price,Cost,Stock,Allocated,Free",
							"1=1",
							"stock_code")
					COMMAND "Customers"
						LET tmp = gl_lookup3( "customer",
							"customer_code,customer_name,contact_name,total_invoices,outstanding_amount",
							"_,Customer,Contact,Invoices,Balance",
							"1=1",
							"customer_name")
				END MENU
&else
				MENU "" ATTRIBUTES(STYLE="popup")
					COMMAND "systables"
						LET tmp = gl_lookup( "systables",
							"tabname,created,nrows,rowsize,(nrows*rowsize)",
							"Name,Created,Rows,RowSize,Total",
							"CDIII",
							"tabid>99",
							"tabname")
					COMMAND "Stock"
						LET tmp = gl_lookup( "stock",
							"stock_code,description,stock_cat,pack_flag,supp_code,price,cost,physical_stock,allocated_stock,free_stock",
							"Code~5,Description~25,Cat~2,Pack~1,Supplier~10,Price,Cost,Stock,Allocated,Free",
							"CCCCCNNIII",
							"1=1",
							"stock_code")
					COMMAND "Customers"
						LET tmp = gl_lookup( "customer",
							"customer_code,customer_name,contact_name,total_invoices,outstanding_amount",
							"_,Customer,Contact,Invoices,Balance",
							"CCCNN",
							"1=1",
							"customer_name")
				END MENU
&endif
				MESSAGE "Selected Row:",tmp

			ON KEY (F2)
				CALL fgl_winmessage("Information", "This is Information", "info")

			ON KEY (F19)
      			LET m_answer = gl_winquestion("My Question",
                	"Did you really mean to ask this?", "Yes", "Yes|No|Cancel", "question" )
						MESSAGE "Result:",m_answer

			COMMAND "poly1"
				LET scal = scal - 50
				IF scal = 300 THEN LET scal = 250 END IF
				IF scal < 0 THEN LET scal = 600 END IF
				CALL star(scal,lins)

			COMMAND "poly2"
				LET scal = scal + 50
				IF scal = 300 THEN LET scal = 350 END IF
				IF scal = 600 THEN LET scal = 0 END IF
				CALL star(scal,lins)

			COMMAND "lines"
				CASE lins
					WHEN TRUE LET lins = FALSE
					WHEN FALSE LET lins = TRUE
				END CASE
				CALL star(scal,lins)

			COMMAND "pie"
				LET chart_typ = "P"
				CALL chart_demo(chart_key,chart_typ)

			COMMAND "bar"
				LET chart_typ = "B"
				CALL chart_demo(chart_key,chart_typ)

			COMMAND "crt"
				LET chart_key = NOT chart_key
				DISPLAY BY NAME chart_key 
				CALL chart_demo(chart_key,chart_typ)

			ON ACTION error
				CALL fgl_winmessage("Error!", "This is an Error", "exclamation")

			ON ACTION error2
				CALL fgl_winmessage("Error!", "This is another Error", "exclamation")

			ON ACTION less 
				CALL hide_item("Page","arrays",1)
				CALL hide_item("Page","canvas",1)
				CALL hide_item("Page","colours",1)

			ON ACTION more
				CALL hide_item("Page","arrays",0)
				CALL hide_item("Page","canvas",0)
				CALL hide_item("Page","colours",0)

			ON ACTION help
				RUN "fglrun editfile help.txt RH"
--				CALL show_src("src", "help.txt", "")
--				MESSAGE "Help!"
--				CALL fgl_winmessage("Help", "No Help Available", "info")
-- Topmenu Source 4gl
			ON ACTION src_4gl
				CALL show_src("src", "widgets.4gl", "")
			ON ACTION src_pb
				CALL show_src("src", "genero_lib1.4gl", "")
			ON ACTION src_shwf
				CALL show_src("src", "showfile.4gl", "")
			ON ACTION src_shwt
				CALL show_src("src", "editfile.4gl", "")
			ON ACTION src_progbar
				CALL show_src("src", "widgets.4gl", "gl_progBar")
			ON ACTION src_idle
				CALL show_src("src", "widgets.4gl", "ON IDLE")
			ON ACTION src_winme
				CALL show_src("src", "widgets.4gl", "fgl_winmess")
			ON ACTION src_winqu
				CALL show_src("src", "widgets.4gl", "fgl_winquest")
			ON ACTION src_hide
				CALL show_src("src", "widgets.4gl", "hide")
			ON ACTION src_md
				CALL show_src("src", "widgets210.4gl", "DIALOG")

-- Topmenu Source per
			ON ACTION src_per
				CALL show_src("forms", "widgets.per", "Section")
			ON ACTION src_tab
				CALL show_src("forms", "table.per", "")
			ON ACTION src_new
				CALL show_src("forms", "newwin.per", "")
			ON ACTION src_tm
				CALL show_src("forms", "widgets.per", "TOPMENU")

-- Topmenu Source xml
			ON ACTION src_ad
				CALL show_src("src", "mydefaults.4ad", "")
			ON ACTION src_tb
				CALL show_src("src", "mydefaults.4tb", "")
			ON ACTION src_sm
				CALL show_src("src", "mydefaults.4sm", "")
			ON ACTION src_st
				CALL show_src("src", "mydefaults.4st", "")
			ON ACTION src_st2
				CALL show_src("src", "mydefaults2.4st", "")

			COMMAND "exit" "Exit Program"
				LET func = "Q"
				EXIT DIALOG
		END DIALOG

		CASE func
			WHEN "0"
				CALL chg_styles("mydefaults")
				CALL ui.interface.setImage( gl_progicon )
				CONTINUE WHILE
			WHEN "1"
				CALL chg_styles("mydefaults1")
				CALL ui.interface.setImage( gl_progicon )
				CONTINUE WHILE
			WHEN "2"
				CALL chg_styles("mydefaults2")
				CALL ui.interface.setImage( gl_progicon )
				CONTINUE WHILE
			WHEN "3"
				CALL chg_styles("mydefaults3")
				CALL g_win.setImage("ibm_genero24")
				CONTINUE WHILE
			WHEN "I"
				CALL do1()
				CONTINUE WHILE
			WHEN "A"
				CALL do2()
			WHEN "D"
				CALL do3()
			WHEN "c"
				CALL colours(TRUE)
			WHEN "Y"
				CALL dynamic()
		END CASE
	END WHILE

	CLOSE WINDOW widgets

END MAIN
--------------------------------------------------------------------------------
-- Do an input by name on the all the widgets.
FUNCTION do1()
	DEFINE val1,val2 CHAR(1)
--NOTE val1/2 are noentry fields.
	INPUT BY NAME norm, normbe,wordw, 
								dec, formt, check, 
								radio, combo, c_year, 
								dateedit, timeedit, datetimeedit,
  							slider,spinedit,
								val1,val2 ATTRIBUTES(UNBUFFERED, WITHOUT DEFAULTS)

		ON ACTION dialogTouched
			MESSAGE "Touched!"
			CALL DIALOG.setActionActive("dialogtouched", FALSE)
			
		ON ACTION touchNorm
			LET norm = "Touched by DISPLAY BY NAME"
			DISPLAY BY NAME norm

		ON ACTION touchNorm2
			LET norm = "Touched by setFieldTouched"
			CALL DIALOG.setFieldTouched("formonly.norm", TRUE)

		ON ACTION isTouched
			IF DIALOG.getFieldTouched("formonly.norm") THEN
				CALL fgl_winMessage("Touched?","norm was touched!","information")
			ELSE
				CALL fgl_winMessage("Touched?","norm remains untouched.","information")
			END IF

		ON ACTION help
			CALL fgl_winmessage("Help", "No Help Available", "info")

		BEFORE INPUT
			DISPLAY "---------- BEFORE INPUT"
--			CALL chg_flds()
			DISPLAY 1 TO combo

		AFTER INPUT
			DISPLAY "---------- AFTER INPUT"
--			CALL chg_flds()

		ON ACTION chg_flds
			DISPLAY "---------- ON ACTION"
			CALL chg_flds()

		ON ACTION src_per
			CALL show_src("src", "widgets.per", fgl_dialog_getfieldname() )	

		ON ACTION src_4gl
			CALL show_src("src", "widgets.4gl", fgl_dialog_getfieldname() )	

		ON ACTION lookup
			CALL lookup1("D")

		ON ACTION lookup1
			CALL lookup1("D")
	
		BEFORE FIELD norm
			DISPLAY "---------- BEFORE FIELD"
			CALL chg_flds()
			DISPLAY 1 TO progress

		AFTER FIELD norm
			DISPLAY "LastKey:",fgl_lastKey()
			IF DOWNSHIFT(norm) = "error" THEN
				ERROR "You entered error!"
			END IF


--		ON ACTION NEXTFIELD
--			DISPLAY "NextField"

		BEFORE FIELD normbe
			CALL setFieldValue("formonly.normbe","ButtonEdit")
			LET normbe = "Testing"
			DISPLAY 2 TO progress

		AFTER FIELD normbe
			DISPLAY "LastKey:",fgl_lastKey()

		BEFORE FIELD wordw
			DISPLAY 3 TO progress

		AFTER FIELD wordw
			DISPLAY "LastKey:",fgl_lastKey()

		BEFORE FIELD dec 
			DISPLAY 4 TO progress

		BEFORE FIELD formt
			DISPLAY 5 TO progress

		BEFORE FIELD check
			DISPLAY 6 TO progress
		AFTER FIELD check
			DISPLAY check TO val1

		ON CHANGE check
			DISPLAY check TO val1

		BEFORE FIELD radio
			DISPLAY 7 TO progress
		AFTER FIELD radio
			DISPLAY radio TO val2
	
		ON CHANGE radio
			CALL set_combo(radio)
			DISPLAY combo TO val3

		BEFORE FIELD combo 
			CALL set_combo(radio)
			DISPLAY 8 TO progress
		ON CHANGE combo
			DISPLAY combo TO val3

		BEFORE FIELD dateedit
			DISPLAY 9 TO progress

		BEFORE FIELD slider
			DISPLAY 10 TO progress
		
		ON CHANGE slider
			LET spinedit = slider

		ON CHANGE spinedit
			LET  slider = spinedit

		BEFORE FIELD spinedit
			DISPLAY 11 TO progress

		ON KEY (F17)
			CALL fgl_winmessage("Information", "This is Information", "info")
		ON KEY (F18)
			CALL fgl_winmessage("Error!", "This is an Error", "exclamation")
	END INPUT

END FUNCTION
--------------------------------------------------------------------------------
-- Input array code.
FUNCTION do2()
	
	CALL change_tb("arr")

	LET int_flag = FALSE
	CALL set_count(arrmax)
	INPUT ARRAY oldarr WITHOUT DEFAULTS FROM oldarr.* --ATTRIBUTE( DELETE ROW=FALSE )
		BEFORE ROW,INSERT
			MESSAGE "Current Row",arr_curr()," of ",arr_count()," LastKey:",fgl_lastKey()
		ON ACTION help
			CALL fgl_winmessage("Help", "No Help Available", "info")

		AFTER FIELD arr1
			DISPLAY oldarr[1].arr1 TO oldarr[1].arr1 ATTRIBUTE(red)
		ON KEY(F31)
			CALL sort(1,1)
		ON KEY(F32)
			CALL sort(2,1)
		ON KEY(F33)
			CALL sort(3,1)
	END INPUT
	IF int_flag THEN RETURN END IF

	INPUT ARRAY oldarr WITHOUT DEFAULTS FROM arr2.*
		BEFORE ROW,INSERT
			MESSAGE "Current Row",arr_curr()," of ",arr_count()," LastKey:",fgl_lastKey()
		ON ACTION help
			CALL fgl_winmessage("Help", "No Help Available", "info")

		ON KEY(F31)
			CALL sort(1,2)
		ON KEY(F32)
			CALL sort(2,2)
		ON KEY(F33)
			CALL sort(3,2)
	END INPUT
	IF int_flag THEN RETURN END IF

	INPUT ARRAY arr WITHOUT DEFAULTS FROM newarr.*
		BEFORE ROW,INSERT
			MESSAGE "Current Row",arr_curr()," of ",arr_count()," LastKey:",fgl_lastKey()
		BEFORE DELETE
			DISPLAY "Before Delete."
		AFTER DELETE
			DISPLAY "After Delete."
		ON ACTION help
			CALL fgl_winmessage("Help", "No Help Available", "info")

		AFTER FIELD tabc1
			DISPLAY arr[1].tabc1 TO newarr[1].tabc1 ATTRIBUTE(red)
			DISPLAY arr[2].tabc3 TO newarr[2].tabc3 ATTRIBUTE(blue)
		ON ACTION lookup1
			CALL lookup1("I")
	END INPUT

	CALL change_tb(g_defs)

END FUNCTION
--------------------------------------------------------------------------------
-- Data sorting routine, fake column sort ( not need now because of real tables)
FUNCTION sort(num,arrnum)
	DEFINE num SMALLINT
	DEFINE arrnum SMALLINT
	DEFINE x,x1 SMALLINT

	IF num = 1 THEN
		CASE sort1
			WHEN TRUE LET sort1 = FALSE
			WHEN FALSE LET sort1 = TRUE
		END CASE
	END IF
	IF num = 2 THEN
		CASE sort2
			WHEN TRUE LET sort2 = FALSE
			WHEN FALSE LET sort2 = TRUE
		END CASE
	END IF
	IF num = 3 THEN
		CASE sort3
			WHEN TRUE LET sort3 = FALSE
			WHEN FALSE LET sort3 = TRUE
		END CASE
	END IF

	FOR x = 1 TO arrmax-1
		FOR x1 = 1 TO arrmax-1
			IF num = 1 THEN
				IF sort1 THEN
					IF oldarr[x1].arr1 > oldarr[x1+1].arr1 THEN
						CALL swap1(x1)
					END IF	
				ELSE
					IF oldarr[x1+1].arr1 > oldarr[x1].arr1 THEN
						CALL swap2(x1)
					END IF	
				END IF	
			END IF
			IF num = 2 THEN
				IF sort2 THEN
					IF oldarr[x1].arr2 > oldarr[x1+1].arr2 THEN
						CALL swap1(x1)
					END IF	
				ELSE
					IF oldarr[x1+1].arr2 > oldarr[x1].arr2 THEN
						CALL swap2(x1)
					END IF	
				END IF	
			END IF
			IF num = 3 THEN
				IF sort3 THEN
					IF oldarr[x1].arr3 > oldarr[x1+1].arr3 THEN
						CALL swap1(x1)
					END IF	
				ELSE
					IF oldarr[x1+1].arr3 > oldarr[x1].arr3 THEN
						CALL swap2(x1)
					END IF	
				END IF	
			END IF
		END FOR
	END FOR

	LET x1 = arr_curr()
	LET x1 = x1 - ( scr_line() - 1 )
	FOR x = 1 TO 5
		IF arrnum = 1 THEN
			DISPLAY oldarr[x1].arr1 TO arr[x].arr1
			DISPLAY oldarr[x1].arr2 TO arr[x].arr2
			DISPLAY oldarr[x1].arr3 TO arr[x].arr3
		ELSE
			DISPLAY oldarr[x1].arr1 TO arr2[x].arr4
			DISPLAY oldarr[x1].arr2 TO arr2[x].arr5
			DISPLAY oldarr[x1].arr3 TO arr2[x].arr6
		END IF
		LET x1 = x1 + 1
	END FOR

END FUNCTION
--------------------------------------------------------------------------------
-- part of sort routine
FUNCTION swap1(x1)
	DEFINE x1 SMALLINT
	DEFINE tmp CHAR(10)

	LET tmp = oldarr[x1+1].arr1
	LET oldarr[x1+1].arr1 = oldarr[x1].arr1
	LET oldarr[x1].arr1 = tmp
	LET tmp = oldarr[x1+1].arr2
	LET oldarr[x1+1].arr2 = oldarr[x1].arr2
	LET oldarr[x1].arr2 = tmp
	LET tmp = oldarr[x1+1].arr3
	LET oldarr[x1+1].arr3 = oldarr[x1].arr3
	LET oldarr[x1].arr3 = tmp

END FUNCTION
--------------------------------------------------------------------------------
-- part of sort routine
FUNCTION swap2(x1)
	DEFINE x1 SMALLINT
	DEFINE tmp CHAR(10)

	LET tmp = oldarr[x1].arr1
	LET oldarr[x1].arr1 = oldarr[x1+1].arr1
	LET oldarr[x1+1].arr1 = tmp
	LET tmp = oldarr[x1].arr2
	LET oldarr[x1].arr2 = oldarr[x1+1].arr2
	LET oldarr[x1+1].arr2 = tmp
	LET tmp = oldarr[x1].arr3
	LET oldarr[x1].arr3 = oldarr[x1+1].arr3
	LET oldarr[x1+1].arr3 = tmp

END FUNCTION
--------------------------------------------------------------------------------
-- Display array code.
FUNCTION do3()

	CALL change_tb("arr")
	CALL set_count(20)
	DISPLAY ARRAY oldarr TO oldarr.*
		ON KEY(F31)
			CALL sort(1,1)
		ON KEY(F32)
			CALL sort(2,1)
		ON KEY(F33)
			CALL sort(3,1)
	END DISPLAY

	DISPLAY ARRAY oldarr TO arr2.*
		ON KEY(F31)
			CALL sort(1,2)
		ON KEY(F32)
			CALL sort(2,2)
		ON KEY(F33)
			CALL sort(3,2)
	END DISPLAY
	
	DISPLAY ARRAY arr TO newarr.*
		BEFORE DISPLAY
			CALL fgl_set_arr_curr(2)
		ON ACTION lookup1
			CALL lookup1("D")
	END DISPLAY
	CALL change_tb(g_defs)

END FUNCTION
--------------------------------------------------------------------------------
-- Display array in a window
FUNCTION lookup1(d_i)
	DEFINE d_i CHAR(1)
	
	OPEN WINDOW lk1 WITH FORM "table"
	
	IF d_i = "D" THEN
		DISPLAY "A Display Array" TO tabtitl
		DISPLAY ARRAY newarr2 TO newarr2.* -- ATTRIBUTES(COUNT=20)
			ON ACTION be
				ERROR "be row",arr_curr()
		END DISPLAY
--			BEFORE DISPLAY
--				CALL ui.interface.refresh()
--				EXIT DISPLAY
--			ON IDLE 1
--				EXIT DISPLAY
--		END DISPLAY
--		MENU "done"
--			COMMAND "cancel"
--				EXIT MENU
--			ON ACTION close
--				EXIT MENU
--		END MENU
	ELSE
		DISPLAY "An Input Array" TO tabtitl
		INPUT ARRAY newarr2 WITHOUT DEFAULTS FROM  newarr2.* -- ATTRIBUTES(COUNT=20)
			ON ACTION be
				ERROR "be row",arr_curr()
		END INPUT
	END IF
	
	CLOSE WINDOW lk1

END FUNCTION
--------------------------------------------------------------------------------
-- Initialize the combobox, dynamically coded when form opened
FUNCTION init_combo( cb )
	DEFINE cb ui.ComboBox
		
	GL_DBGMSG(2,"init_combo: start")
	CALL set_combo("?")
	GL_DBGMSG(2,"init_combo: done")

END FUNCTION
--------------------------------------------------------------------------------
-- Initialize the combobox, dynamically coded when form opened
FUNCTION init_combo2( cb )
	DEFINE cb ui.ComboBox
	DEFINE y,x SMALLINT

	LET y = YEAR(CURRENT)
	CALL cb.addItem(NULL,NULL)
	FOR x = y TO y-80 STEP -1
	--FOR x = y-80 TO y
		CALL cb.addItem(x,x)
	END FOR

END FUNCTION
--------------------------------------------------------------------------------
-- Sets value in the combobox
FUNCTION set_combo( opt )
	DEFINE opt CHAR(1)
	DEFINE cb ui.ComboBox
	DEFINE rec ARRAY [10] OF RECORD
		mykey INTEGER,
		mydesc CHAR(20)
		END RECORD
	DEFINE x SMALLINT

	LET cb = ui.ComboBox.forName("combo")

	LET rec[1].mykey = 1 LET rec[1].mydesc = "Astra"
	LET rec[2].mykey = 2 LET rec[2].mydesc = "Corsa"
	LET rec[3].mykey = 3 LET rec[3].mydesc = "Tigra"
	LET rec[4].mykey = 4 LET rec[4].mydesc = "Vectra"

	CALL cb.clear()

	CASE opt 
		WHEN "F"
			CALL cb.addItem(1,"Cougar")
			CALL cb.addItem(2,"Escort")
			CALL cb.addItem(3,"Fiesta")
			CALL cb.addItem(4,"Focus")
			CALL cb.addItem(5,"Ka")
			CALL cb.addItem(6,"Mondeo")
		WHEN "R"
			CALL cb.addItem(1,"Espace")
			CALL cb.addItem(2,"Clio")
			CALL cb.addItem(3,"Modus")
			CALL cb.addItem(4,"Kangoo")
			CALL cb.addItem(5,"Megane Hatch")
			CALL cb.addItem(6,"Megane Saloon")
			CALL cb.addItem(7,"Megane Tourer")
			CALL cb.addItem(8,"Megane Coupe-Cabriolet")
			CALL cb.addItem(9,"Scenic")
			CALL cb.addItem(10,"Laguna Hatch")
			CALL cb.addItem(11,"Laguna Tourer")
		WHEN "C"
			CALL cb.addItem(1,"1|AX")
			CALL cb.addItem(2,"2|BX")
			CALL cb.addItem(3,"3|C3")
			CALL cb.addItem(4,"4|C5")
			CALL cb.addItem(5,"5|C8")
			CALL cb.addItem(6,"6|CX")
		WHEN "V"
			FOR x = 1 TO 4
				CALL cb.addItem(rec[x].mykey,rec[x].mykey||" "||rec[x].mydesc)
			END FOR
		OTHERWISE
			CALL cb.addItem(1,"Please")
			CALL cb.addItem(2,"Choose")
			CALL cb.addItem(3,"A Make")
	END CASE

END FUNCTION
--------------------------------------------------------------------------------
-- Demo of dynamic fields
FUNCTION dynamic()
	DEFINE field_name CHAR(18)
	DEFINE field_type CHAR(18)
	DEFINE field_size SMALLINT
	DEFINE win_obj ui.Window
	DEFINE frm_obj ui.Form
	DEFINE lst om.NodeList
	DEFINE dellst om.NodeList
	DEFINE win_node om.DomNode
	DEFINE grp_node om.DomNode
	DEFINE new_node om.DomNode
	DEFINE y,tog SMALLINT

	LET win_obj = ui.Window.getCurrent()
	LET win_node = win_obj.getNode()
	IF win_node IS NULL THEN
		DISPLAY "dynamic: Failed to get node for window!"
		RETURN
	END IF
	LET lst = win_node.selectByPath("//Group[@text='New Fields']")
	IF lst.getLength() < 1 THEN
		DISPLAY "dynamic: XPATH Failed to find node for group!"
		RETURN
	END IF 

	LET grp_node = lst.item(1)
	IF grp_node IS NULL THEN
		DISPLAY "dynamic: Failed to get node for group!"
		RETURN
	END IF

	LET frm_obj = win_obj.getForm()
	CALL frm_obj.setElementHidden("formonly.field_size",2) -- hide field
	CALL frm_obj.setElementHidden("dlab3",2) -- hide label
	LET y = 1
	LET tog = TRUE
	WHILE TRUE
		LET int_flag = FALSE
		LET field_size = 10
		INPUT BY NAME field_name, field_type, field_size WITHOUT DEFAULTS
			ON ACTION sze
				IF tog THEN
					CALL frm_obj.setElementImage("sze","rewind")
					CALL frm_obj.setElementText("sze","less")
					CALL frm_obj.setElementHidden("dlab3",0) -- unhide label
					CALL frm_obj.setElementHidden("formonly.field_size",0)
				ELSE
					CALL frm_obj.setElementImage("sze","forwind")
					CALL frm_obj.setElementText("sze","more")
					CALL frm_obj.setElementHidden("dlab3",1) -- hide label
					CALL frm_obj.setElementHidden("formonly.field_size",1)
				END IF
				LET tog = NOT tog
			ON KEY (ESCAPE) LET int_flag = TRUE
			ON KEY (F9)
				LET dellst = win_node.selectByPath("//Group[@text='New Fields']/*")
				FOR y = 1 TO dellst.getLength()
					LET new_node = dellst.item(y)
					CALL grp_node.removeChild(new_node)
				END FOR
				LET y = 1
		END INPUT
		IF int_flag THEN EXIT WHILE END IF
		IF field_name IS NULL OR field_type IS NULL THEN
			CONTINUE WHILE
		END IF

		LET new_node = grp_node.createChild("Label")
		IF new_node IS NULL THEN
			DISPLAY "dynamic: Failed to create new node Label!"
			EXIT WHILE
		END IF
		CALL new_node.setAttribute("name",field_name CLIPPED)
		CALL new_node.setAttribute("text",field_name CLIPPED)
		CALL new_node.setAttribute("justify","right")
		CALL new_node.setAttribute("posX",1)
		CALL new_node.setAttribute("posY",y)

		LET new_node = grp_node.createChild("FormField")
		IF new_node IS NULL THEN
			DISPLAY "dynamic: Failed to create new node FormField!"
			EXIT WHILE
		END IF
		CALL new_node.setAttribute("colName",field_name CLIPPED)
		LET new_node = new_node.createChild(field_type CLIPPED)
		IF new_node IS NULL THEN
			DISPLAY "dynamic: Failed to create new node "||field_type||"!"
			EXIT WHILE
		END IF
		WHENEVER ERROR CONTINUE
		CALL new_node.setAttribute("gridWidth",field_size )
		IF STATUS != 0 THEN
			ERROR "Failed:",STATUS
		END IF
		WHENEVER ERROR STOP
		CALL new_node.setAttribute("text",field_name CLIPPED)
		CALL new_node.setAttribute("width",field_size )
		CALL new_node.setAttribute("posX",20)
		CALL new_node.setAttribute("posY",y)
		LET y = y + 1
	END WHILE

END FUNCTION
--------------------------------------------------------------------------------
-- Build a string with HTML tags to display in a TEXTEDIT widget.
FUNCTION textedit()
	DEFINE txt2 CHAR(2000)
	DEFINE f ui.Form
	DEFINE w,v,g,n,h om.domNode
	DEFINE edt SMALLINT

	OPEN WINDOW te AT 1,1 WITH 1 ROWS, 1 COLUMNS ATTRIBUTE(STYLE="naked")

	LET w = gl_genForm("Textedit")
	CALL w.setAttribute("text","Textedit Demo")
	LET v = w.createChild("VBox")
	LET n = v.createChild("Grid")
	LET g = n.createChild("Group")
	CALL g.setAttribute("text","TextEdit")
	LET n = g.createChild("FormField")
	CALL n.setAttribute("colName","txt2")
	CALL n.setAttribute("name","txt2")
	LET n = n.createChild("TextEdit")
	CALL n.setAttribute("name","txtedt2")
	CALL n.setAttribute("posY","1")
	CALL n.setAttribute("scroll","1")
	CALL n.setAttribute("stretch","both")
	CALL n.setAttribute("style","html find spell")
	CALL n.setAttribute("width","58")
	CALL n.setAttribute("height","11")
	LET h = v.createChild("HBox")
	CALL h.setAttribute("posY","2")
	LET g = h.createChild("Grid")
	LET n = g.createChild("Button")
	CALL n.setAttribute("posX","1")
	CALL n.setAttribute("name","exit")
	CALL n.setAttribute("text","")
	LET n = g.createChild("Button")
	CALL n.setAttribute("posX","20")
	CALL n.setAttribute("name","edit")
	CALL n.setAttribute("image","pen")
	LET n = g.createChild("Button")
	CALL n.setAttribute("posX","30")
	CALL n.setAttribute("name","accept")
	LET n = g.createChild("Button")
	CALL n.setAttribute("posX","40")
	CALL n.setAttribute("name","cancel")

	LET txt2 = "<B>Bold</B> - <U>Underline</U> - <I>Italic</I><BR>"
	LET txt2 = txt2 CLIPPED,'<FONT NAME="arial" SIZE="12" COLOR="#1234E3">Colours & Fonts</FONT>'
	LET txt2 = txt2 CLIPPED,'<P ALIGN=CENTER>Centered Text & Table'

	LET txt2 = txt2 CLIPPED,'<TABLE BORDER=1>'
	LET txt2 = txt2 CLIPPED,'<TR BGCOLOR="#0000FF">'
	LET txt2 = txt2 CLIPPED,'<TH><FONT COLOR="#FFFFFF"><B>Product</B></TH>'
	LET txt2 = txt2 CLIPPED,'<TH ALIGN="RIGHT"><FONT COLOR="#FFFFFF"><B>Qty</B></TH>'
	LET txt2 = txt2 CLIPPED,'<TH ALIGN="RIGHT"><FONT COLOR="#FFFFFF"><B>Value</B></TH>'
	LET txt2 = txt2 CLIPPED,'<TH ALIGN="RIGHT"><FONT COLOR="#FFFFFF"><B>Total</B></TH></TR>'

	LET txt2 = txt2 CLIPPED,'<TR BGCOLOR="cyan"><TD>Line 1</TD><TD ALIGN="RIGHT">2</TD><TD ALIGN="RIGHT">15.99</TD><TD ALIGN="RIGHT">31.98</TD></TR>'
	LET txt2 = txt2 CLIPPED,'<TR BGCOLOR="cyan"><TD>Line 2</TD><TD ALIGN="RIGHT">12</TD><TD ALIGN="RIGHT">3.99</TD><TD ALIGN="RIGHT">47.88</TD></TR>'
	LET txt2 = txt2 CLIPPED,"</TABLE>"
	LET txt2 = txt2 CLIPPED,'</P>'
	LET f = gl_getForm(NULL)
	DISPLAY BY NAME txt2
--	WHILE TRUE
		LET edt = FALSE
		MENU "Options"
			COMMAND "exit" "Close Window"
				EXIT MENU
			--COMMAND "Edit" "Edit"
				--LET edt = TRUE
				--EXIT MENU
			COMMAND KEY (ESC)
				EXIT MENU
		END MENU
		--CALL f.setElementStyle("txtedt2","htmledit spell find")
		--CALL ui.Interface.refresh()
		--INPUT BY NAME txt2
--	END WHILE
	CLOSE WINDOW te

END FUNCTION
--------------------------------------------------------------------------------
-- Onidle demo using a dynamically created form.
FUNCTION onidle()
	DEFINE idle_time,ret SMALLINT
	DEFINE txt CHAR(80)
	DEFINE win, frm, grid, frmf, comb om.DomNode
	DEFINE f ui.Form
	DEFINE uiwin ui.Window
	DEFINE cb ui.ComboBox
--FIXME
	OPEN WINDOW onidle WITH 1 ROWS, 1 COLUMNS

	LET uiwin = ui.Window.GetCurrent()
	LET win = uiwin.GetNode()
	CALL win.setAttribute("style","naked")

	LET f = uiwin.createForm("IdleTime")
	LET frm = f.getNode()
	CALL frm.setAttribute("text","Select Idle time")
	LET grid = frm.createChild('Grid')
	CALL grid.setAttribute("height","5")
	CALL grid.setAttribute("width","30")
	LET frmf = grid.createChild('Label')
	CALL frmf.setAttribute("text","Please select an Idle time then press RETURN or TAB:")
	CALL frmf.setAttribute("posX","1")
	CALL frmf.setAttribute("posY","1")
	LET frmf = grid.createChild('FormField')
	CALL frmf.setAttribute("colName","idle_time")
	CALL frmf.setAttribute("name","idle_time")
	LET comb = frmf.createChild('ComboBox')
	CALL comb.setAttribute("name","idle_time")
	CALL comb.setAttribute("posX","1")
	CALL comb.setAttribute("posY","2")
	CALL comb.setAttribute("height","4")
	CALL comb.setAttribute("width","20")
	LET frmf = grid.createChild('Label')
	CALL frmf.setAttribute("posX","1")
	CALL frmf.setAttribute("posY","10")

	LET cb = ui.ComboBox.forName("idle_time")
	IF cb IS NULL THEN 
		ERROR "Failed to find idle_time!" 
		CLOSE WINDOW onidle
		RETURN
	END IF
	FOR idle_time = 2 TO 20 STEP 2
		LET txt = idle_time USING "<&"," Seconds"
		CALL cb.addItem(idle_time,txt CLIPPED)
	END FOR

	LET idle_time = 4

	LET ret = FALSE	
	WHILE NOT ret
		LET txt = "Current Idle Time is : ",idle_time USING "<&"
		CALL frmf.setAttribute("text",txt)
		INPUT BY NAME idle_time WITHOUT DEFAULTS ATTRIBUTES(UNBUFFERED)
			ON IDLE idle_time
				LET ret = FALSE
				LET txt = "You were idle for ", idle_time USING "<&"," Seconds, Exit Input?"
				MENU "Idle Input"  ATTRIBUTES(STYLE="dialog", COMMENT=txt)
					COMMAND "Continue"
						LET ret = FALSE
					COMMAND "Exit"
						LET ret = TRUE
				END MENU
				EXIT INPUT
		END INPUT
		IF int_flag THEN LET ret = TRUE END IF
	END WHILE

	CLOSE WINDOW onidle

END FUNCTION
--------------------------------------------------------------------------------
-- Add a table to a form dynamically
FUNCTION dyntab()

	DEFINE win ui.Window
	DEFINE nl om.NodeList
	DEFINE n,vb,t,tc,tce om.DomNode
	DEFINE arr DYNAMIC ARRAY OF RECORD
		fld1 CHAR(10),
		fld2 CHAR(10),
		fld3 CHAR(10)
	END RECORD

	LET win = ui.Window.GetCurrent()
	LET n = win.GetNode()
	LET nl = n.selectByPath("//Group[@name='dyntab']")
	IF nl.getLength() > 0 THEN
		LET vb = nl.item(1)
		DISPLAY vb.getTagName()
		LET t = vb.CreateChild("Table") 
		CALL t.setAttribute("tabName","dyntab")
		CALL t.setAttribute("height","5")
		CALL t.setAttribute("pageSize","10")
		CALL t.setAttribute("size","10")

		LET tc = t.CreateChild("TableColumn")
		CALL tc.setAttribute("colName","fld1")
		CALL tc.setAttribute("text","Col1")
		LET tce = tc.CreateChild("Edit")
		CALL tce.setAttribute("width",5)

		LET tc = t.CreateChild("TableColumn")
		CALL tc.setAttribute("colName","fld2")
		CALL tc.setAttribute("text","Col2")
		LET tce = tc.CreateChild("Edit")
		CALL tce.setAttribute("width",5)

		LET tc = t.CreateChild("TableColumn")
		CALL tc.setAttribute("colName","fld3")
		CALL tc.setAttribute("text","Col3")
		LET tce = tc.CreateChild("Edit")
		CALL tce.setAttribute("width",5)
	ELSE
		DISPLAY "No page found."
		RETURN
	END IF

	LET arr[1].fld1 = "a1"
	LET arr[1].fld2 = "b1"
	LET arr[1].fld3 = "c1"
	LET arr[2].fld1 = "a2"
	LET arr[2].fld2 = "b2"
	LET arr[2].fld3 = "c2"
	DISPLAY ARRAY arr TO dyntab.* ATTRIBUTE(COUNT=2)

END FUNCTION
--------------------------------------------------------------------------------
-- Window styles demo function
FUNCTION disp_newwin(stl,txt)
	DEFINE stl STRING
	DEFINE txt STRING

	OPEN WINDOW tmp AT 1,1 WITH FORM "newwin" ATTRIBUTE(style=stl, text=txt)
	DISPLAY "anykey.jpg" TO img
	DISPLAY ARRAY newarr3 TO arr.* ATTRIBUTES(COUNT=10)
		BEFORE DISPLAY
			IF stl != "dialog" THEN
				EXIT DISPLAY
			END IF
	END DISPLAY
	IF stl != "dialog" THEN
		MENU "RingMenu"
			ON ACTION cancel
				EXIT MENU
			ON ACTION accept
				EXIT MENU
			COMMAND KEY (f20)
				ERROR "Test Error Message"
			COMMAND "Exit"
				EXIT MENU
		END MENU
	END IF
	CLOSE WINDOW tmp

END FUNCTION
--------------------------------------------------------------------------------
-- Form initializer - NOT USED
FUNCTION Init_Forms(frm)
	DEFINE winn,lab om.DomNode
	DEFINE frm ui.Form
	DEFINE nl om.NodeList

	DISPLAY "init_form:"
	LET winn = frm.GetNode()

	LET nl = winn.selectByPath("//Label[@name='slab1']")
	IF nl.getLength() > 0 THEN
		DISPLAY "init_form: Setting attribute for slab1"
		LET lab = nl.item(1)
		CALL lab.setAttribute("color","red")
	ELSE
		DISPLAY "init_form: Don't find slab1!!"
	END IF

END FUNCTION
--------------------------------------------------------------------------------
-- Changes the toolbar - used to switch toolbar for array navigation.
FUNCTION change_tb(tb)
	DEFINE tb STRING

	DISPLAY "Widgets: Changing Toolbar to '"||tb||"'"
	CALL g_frm.loadToolbar(tb)

END FUNCTION
--------------------------------------------------------------------------------
-- Changs the style file 
FUNCTION chg_styles(s_file)
	DEFINE s_file STRING

	CLOSE WINDOW widgets

	DISPLAY "Widgets: Changing Styles to '"||s_file||"'"
	CALL ui.Interface.loadStyles(s_file)

	OPEN WINDOW widgets WITH FORM "widgets"
	CALL disp_form()

	IF s_file = "mydefaults3" THEN
		CALL change_tb("mydefaults3")
	END IF

	CALL ui.Interface.refresh()

END FUNCTION
--------------------------------------------------------------------------------
-- Fill the form with data
FUNCTION disp_form()
	
	LET g_win = ui.Window.getCurrent()
	LET g_frm = g_win.getForm()

	CALL colours(FALSE)

	DISPLAY "four_js_small" TO jpg
	DISPLAY "widgets_ani.gif" TO gif
	DISPLAY "widgetsbmp" TO bmp
	DISPLAY "widgetspng" TO png
	DISPLAY "widgetssvg" TO svg

	--DISPLAY "Edit Field:" TO lab0
	--DISPLAY "ButtonEdit:" TO lab1
	--DISPLAY "TextEdit:" TO lab2
	--DISPLAY "ComboBox:" TO lab3
	--DISPLAY "Check Boxes:" TO lab4
	--DISPLAY "Radio Group:" TO lab5
	--DISPLAY "Date Edit:" TO lab6

	LET norm = "Normal entry"
	LET normbe = "hit here for lookup ->"
	LET dec = 12.34
	LET formt = "A1-12 ABXX"
	LET wordw = "This is some text that as been wordwrapped to fit into this text box. The field in the program is 500 characters.",ASCII(10),"This is on a new line using ASCII(10)"
	LET dateedit = TODAY
	LET timeedit = CURRENT
	LET datetimeedit = CURRENT

	DISPLAY BY NAME norm, normbe, wordw, dec, formt, dateedit, timeedit, datetimeedit -- ATTRIBUTE(RED)
	DISPLAY check TO val1
	DISPLAY radio TO val2
	DISPLAY combo TO val3

	MESSAGE "Looking for Google logo..."
	GL_DBGMSG(2,"Looking for Google logo...")
	CALL ui.interface.refresh()

--	SLEEP 1
	DISPLAY "http://www.google.co.uk/intl/en_uk/images/logo.gif" TO google
	GL_DBGMSG(2,"Done.")

	MESSAGE ""

END FUNCTION
--------------------------------------------------------------------------------
-- Populate the array
FUNCTION arr_set()
	CALL arr.clear()
	LET arr[ arr.getLength() + 1 ].img = "cut"
	LET arr[ arr.getLength() + 1 ].img = "delete"
	LET arr[ arr.getLength() + 1 ].img = "disk"
	LET arr[ arr.getLength() + 1 ].img = "eraser"
	LET arr[ arr.getLength() + 1 ].img = "fileclose"
	LET arr[ arr.getLength() + 1 ].img = "filefind"
	LET arr[ arr.getLength() + 1 ].img = "fileopen"
	LET arr[ arr.getLength() + 1 ].img = "fileprint"
	LET arr[ arr.getLength() + 1 ].img = "filesave"
	LET arr[ arr.getLength() + 1 ].img = "balloon"
	LET arr[ arr.getLength() + 1 ].img = "find"
	LET arr[ arr.getLength() + 1 ].img = "findfile"
	LET arr[ arr.getLength() + 1 ].img = "first"
	LET arr[ arr.getLength() + 1 ].img = "garbage"
	LET arr[ arr.getLength() + 1 ].img = "gobegin"
	LET arr[ arr.getLength() + 1 ].img = "goend"
	LET arr[ arr.getLength() + 1 ].img = "goforw"
	LET arr[ arr.getLength() + 1 ].img = "gorev"
	LET arr[ arr.getLength() + 1 ].img = "hand"
	LET arr[ arr.getLength() + 1 ].img = "heart"
	LET arr[ arr.getLength() + 1 ].img = "help"
	LET arr[ arr.getLength() + 1 ].img = "helpques"
	LET arr[ arr.getLength() + 1 ].img = "hook"
	LET arr[ arr.getLength() + 1 ].img = "key"
	LET arr[ arr.getLength() + 1 ].img = "last"
	LET arr[ arr.getLength() + 1 ].img = "letter"
	LET arr[ arr.getLength() + 1 ].img = "mag"
	LET arr[ arr.getLength() + 1 ].img = "mail"
	LET arr[ arr.getLength() + 1 ].img = "minus"
	LET arr[ arr.getLength() + 1 ].img = "new"
	LET arr[ arr.getLength() + 1 ].img = "next"
	LET arr[ arr.getLength() + 1 ].img = "note"
	LET arr[ arr.getLength() + 1 ].img = "notebook"
	LET arr[ arr.getLength() + 1 ].img = "open"
	LET arr[ arr.getLength() + 1 ].img = "paste"
	LET arr[ arr.getLength() + 1 ].img = "pen"
	LET arr[ arr.getLength() + 1 ].img = "phone"
	LET arr[ arr.getLength() + 1 ].img = "plus"
	LET arr[ arr.getLength() + 1 ].img = "pointer"
	LET arr[ arr.getLength() + 1 ].img = "prev"
	LET arr[ arr.getLength() + 1 ].img = "printer"
	LET arr[ arr.getLength() + 1 ].img = "prop"
	LET arr[ arr.getLength() + 1 ].img = "quest"
	LET arr[ arr.getLength() + 1 ].img = "smiley"
	LET arr[ arr.getLength() + 1 ].img = "speaker"
	LET arr[ arr.getLength() + 1 ].img = "ssmiley"
	LET arr[ arr.getLength() + 1 ].img = "stop"
	LET arr[ arr.getLength() + 1 ].img = "sum"
	LET arr[ arr.getLength() + 1 ].img = "tilehorz"
	LET arr[ arr.getLength() + 1 ].img = "tilevert"
	LET arr[ arr.getLength() + 1 ].img = "time"
	LET arr[ arr.getLength() + 1 ].img = "uplevel"
	LET arr[ arr.getLength() + 1 ].img = "wizard"

END FUNCTION
--------------------------------------------------------------------------------
-- Changes the path for the background image from style file.
FUNCTION fix_path()
	DEFINE nl om.NodeList
	DEFINE n om.DomNode
	DEFINE pth STRING
	DEFINE st base.StringTokenizer
	
	LET n = ui.interface.getRootNode()
	LET nl = n.selectByPath("//Style[@name='.styles']/StyleAttribute")
	
	IF nl.getLength() > 0 THEN
		LET n = nl.item(1)
		LET pth = n.getAttribute("value")
		LET st = base.StringTokenizer.create(pth,"/")
		DISPLAY "Old Path:",pth
		WHILE st.hasMoreTokens()
			LET pth = st.nextToken()
		END WHILE
		CALL n.setAttribute("value",cwd||"pics/"||pth)
		DISPLAY "New Path:",cwd||"pics/"||pth
	ELSE
		DISPLAY "Didn't find node!"
	END IF
	
END FUNCTION
--------------------------------------------------------------------------------
-- Shows a source and highlights lines containing the specified string
FUNCTION show_src(dir, fil,fld )
	DEFINE dir STRING
	DEFINE fil STRING
	DEFINE fld STRING
	DEFINE run_stmt STRING
	
	IF fil = "widgets.4gl" THEN
		CASE fld
			WHEN "norm" LET fld = "INPUT BY NAME"
			WHEN "wordw" LET fld = "N textedit("
			WHEN "radio" LET fld = "set_combo"
		END CASE
	END IF

	LET run_stmt = "fglrun showfile $BASE/"||dir||"/",fil," \"",fld CLIPPED,"\""
	RUN run_stmt

END FUNCTION
--------------------------------------------------------------------------------
-- Canvas demo; drawing a chart.
FUNCTION chart_demo(key,typ)

	DEFINE typ CHAR(1)
	DEFINE key INTEGER
	DEFINE f1,f2,f3,f4,f5,f6 INTEGER
	DEFINE l1,l2,l3,l4,l5,l6 CHAR(20)

	CALL drawinit()
	CALL drawselect("canv")

	LET f1 = 87
	LET f2 = 27
	LET f3 = 79
	LET f4 = 11
	LET f5 = 34
	LET f6 = 56
	LET l1 = "Sales"
	LET l2 = "Returns"
	LET l3 = "PreOrders"
	LET l4 = "Writeoff"
	LET l5 = "Royalty"
	LET l6 = "Taxable"

	CALL cls() -- see clock2.4gl

	LET key = key * 200

	CASE typ
		WHEN "P"
			CALL pie_chart(key,25,25,950,950,f1,l1,f2,l2,f3,l3,f4,l4,f5,l5,f6,l6)
		WHEN "B"	
			CALL bar_chart(key,25,25,950,950,f1,l1,f2,l2,f3,l3,f4,l4,f5,l5,f6,l6)
	END CASE

END FUNCTION
--------------------------------------------------------------------------------
-- Draw star on the canvas
--         1
--        /\
--   3___/  \___4
--    \        /
--      \/  \/
--      5    2   
FUNCTION star(scal,lins)

	DEFINE ret SMALLINT
	DEFINE p1x, p1y SMALLINT
	DEFINE p2x, p2y SMALLINT
	DEFINE p3x, p3y SMALLINT
	DEFINE p4x, p4y SMALLINT
	DEFINE p5x, p5y SMALLINT
	DEFINE scal SMALLINT
	DEFINE lins SMALLINT
	DEFINE scalt CHAR(3)

	DEFINE coors CHAR(60)

	CALL cls() -- see clock2.4gl

	IF scal < 0 THEN LET scal = 0 END IF

	LET p1x = 900 - scal
	LET p1y = 500

	LET p2x = 100 + scal
	LET p2y = 800 - scal

	LET p3x = 700 - scal
	LET p3y = 100 + scal

	LET p4x = 700 - scal
	LET p4y = 900 - scal

	LET p5x = 100 + scal
	LET p5y = 200 + scal

	LET coors = p1x USING "&&&"," ",
				p1y USING "&&&"," ",
				p2x USING "&&&"," ",
				p2y USING "&&&"," ",
				p3x USING "&&&"," ",
				p3y USING "&&&"," ",
				p4x USING "&&&"," ",
				p4y USING "&&&"," ",
				p5x USING "&&&"," ",
				p5y USING "&&&"

	IF lins THEN
		CALL drawfillcolor("white")
		CALL drawlinewidth(2)
-- format is x,y,up,across ( NOTE up,access are relative to x,y )
		CALL drawline(p1x,p1y,p2x-p1x,p2y-p1y) RETURNING ret
		CALL drawline(p2x,p2y,p3x-p2x,p3y-p2y) RETURNING ret
		CALL drawline(p3x,p3y,p4x-p3x,p4y-p3y) RETURNING ret
		CALL drawline(p4x,p4y,p5x-p4x,p5y-p4y) RETURNING ret
		CALL drawline(p5x,p5y,p1x-p5x,p1y-p5y) RETURNING ret
	
		CALL drawfillcolor("yellow")
		CALL drawlinewidth(1)
		CALL drawline(p1x,p1y,p2x-p1x,p2y-p1y) RETURNING ret
		CALL drawline(p2x,p2y,p3x-p2x,p3y-p2y) RETURNING ret
		CALL drawline(p3x,p3y,p4x-p3x,p4y-p3y) RETURNING ret
		CALL drawline(p4x,p4y,p5x-p4x,p5y-p4y) RETURNING ret
		CALL drawline(p5x,p5y,p1x-p5x,p1y-p5y) RETURNING ret
	END IF

	CALL drawfillcolor("red")
-- x y  x y  x y  x y etc ( NOTE: point are NOT relative )
	CALL drawpolygon(coors) RETURNING ret

	CALL drawfillcolor("white")
	CALL drawrectangle (900,20,45,100) RETURNING ret
	LET scalt = (scal / 50) USING "-&"
	CALL drawtext(900,60,scalt) RETURNING ret

END FUNCTION
--------------------------------------------------------------------------------
-- Function to hide/unhide an form item by name.
FUNCTION hide_item(tag,nam,hid)
	DEFINE tag,nam STRING
	DEFINE hid,x SMALLINT
	DEFINE win_obj ui.Window
	DEFINE nl om.NodeList
	DEFINE n om.DomNode

	LET win_obj = ui.Window.getCurrent()
	LET n = win_obj.getNode()
	LET nl = n .selectByPath("//"||tag||"[@name='"||nam||"']")
	FOR x = 1 TO nl.getLength()
		LET n = nl.item(x)
		CALL n.setAttribute("hidden",hid)
--		DISPLAY "Hiding:",n.getAttribute("name")
	END FOR

END FUNCTION
--------------------------------------------------------------------------------
-- Change Active/InActive fields to style 'live'/'dead'
FUNCTION chg_flds()
	DEFINE win ui.Window
	DEFINE frm ui.Form
	DEFINE nl om.NodeList
	DEFINE frm_n, n om.DomNode
	DEFINE x SMALLINT
	DEFINE nam STRING

	LET win = ui.Window.GetCurrent()
	LET frm = win.getForm()
	LET frm_n = frm.getNode()

	LET nl = frm_n.selectByPath("//FormField")
	FOR x = 1 TO nl.getLength()
		LET n = nl.item(x)
		LET nam = n.getAttribute("colName")
		DISPLAY nam,"=",n.getAttribute("active"),"(",n.getAttribute("dialogType"),")"
		IF n.getAttribute("active") THEN
			CALL frm.setFieldStyle(nam,"live")
		ELSE
			CALL frm.setFieldStyle(nam,"dead")
		END IF
	END FOR

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION delay()
	DEFINE x,y INTEGER

	LET y = 0
	FOR x = 1 TO 10000
&ifndef genero13x
		LET y = y + util.math.rand(1000)
&else
		LET y = y + 300 -- ?
&endif
		LET y = y / 3
		MESSAGE "Random Data:",x,y
	END FOR

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION webkit()
	DEFINE url STRING

	OPEN WINDOW webkit WITH FORM "webkit"
	LET int_flag = FALSE
--	LET url = "http://www-eu1.4js.com/mirror/documentation.php?s=genero&p=fgl&f=fjs-fgl-2.20.01-manual.pdf"
	LET url = "http://www.4js.com/online_documentation/fjs-fgl-2.20.02-manual-html/"
	DISPLAY BY NAME url
	DISPLAY url TO browser
	CALL ui.interface.refresh()
	WHILE NOT int_flag
		INPUT BY NAME url ATTRIBUTE(WITHOUT DEFAULTS,UNBUFFERED)
			ON ACTION exit EXIT INPUT
			ON ACTION close EXIT INPUT
			ON ACTION svgclock LET url = "http://borodin/gas230/components/clock/svgclock.svg" EXIT INPUT
			ON ACTION svg LET url = "http://localhost/Talon_std.svg" EXIT INPUT
			ON ACTION google LET url = "http://www.google.com/" EXIT INPUT
			ON ACTION fourjs LET url = "http://www.fourjs.com/" EXIT INPUT
			ON ACTION manual LET url = "http://www.4js.com/online_documentation/fjs-fgl-2.20.02-manual-html/"  EXIT INPUT
		END INPUT
		IF NOT int_flag THEN 
			DISPLAY url TO browser
		END IF
	END WHILE
	CLOSE WINDOW webkit
	LET int_flag = FALSE
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION setFieldValue( fld, val )
	DEFINE fld,val STRING
	DEFINE nl om.NodeList
	DEFINE n om.DomNode

	LET nl = f_n.selectByPath("//FormField[@name='"||fld||"']")
	IF nl.getLength() > 0 THEN
		LET n = nl.item(1)
		DISPLAY "Current value:",n.getAttribute("value")
		CALL n.setAttribute("value",val)
		DISPLAY "Setting value:",val
		CALL ui.Interface.refresh()
	ELSE
		DISPLAY "No found:",fld
	END IF

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION load_new_imgarr(l_fa)
	DEFINE l_fa BOOLEAN
	DEFINE c base.channel
	DEFINE l_rec RECORD 
		fld1 STRING,
		fld2 STRING
	END RECORD
	DEFINE x SMALLINT
	LET c = base.channel.create()
	CALL c.openPipe( "cat "||fgl_getEnv("FGLDIR")||"/lib/image2font.txt | sort","r")
	CALL c.setDelimiter("=")
	WHILE NOT c.isEOF()
		IF c.read( [ l_rec.* ] ) THEN
			DISPLAY l_rec.fld1," Font:",l_rec.fld2
			IF NOT l_fa AND l_rec.fld1.subString(1,3) = "fa-" THEN CONTINUE WHILE END IF
			IF l_fa AND l_rec.fld1.subString(1,3) != "fa-" THEN CONTINUE WHILE END IF
			CALL m_imgrec.appendElement()
			LET m_imgrec[ m_imgrec.getLength() ].img = l_rec.fld1
			LET m_imgrec[ m_imgrec.getLength() ].nam = l_rec.fld1
			LET x = l_rec.fld2.getIndexOf(":",1)
			LET m_imgrec[ m_imgrec.getLength() ].font= l_rec.fld2.subString(1,x-1)
			LET m_imgrec[ m_imgrec.getLength() ].val = l_rec.fld2.subString(x+1, l_rec.fld2.getLength())
		END IF
	END WHILE
	CALL c.close()
END FUNCTION