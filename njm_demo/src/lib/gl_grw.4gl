
#+ Library Functions for Reports for use with Genero Report Writer
#+
#+ $Id: gl_grw.4gl 319 2009-12-17 13:30:28Z  $
#+
#+ This must be link with external dependancies:
#+  $(GREDIR)/lib/libgre.42x
#+
#+ FGLLDPATH must include:
#+ $(GREDIR)/lib/libgre.42x
#+
#+ Can use a java based server side printer detection must compile with
#+ -DgotJAVA

-- com.fourjs.pxml.shared.AttributeException: cannot find printer matching the print request attributes named " \\pinotage\Phaser 8500N PS"

&ifdef gotJAVA
-- Java used for getting printer list.
IMPORT JAVA javax.print.DocFlavor
IMPORT JAVA javax.print.PrintService
IMPORT JAVA javax.print.PrintServiceLookup
IMPORT JAVA javax.print.attribute.HashPrintRequestAttributeSet
IMPORT JAVA javax.print.attribute.PrintRequestAttributeSet
IMPORT JAVA javax.print.attribute.standard.Copies
&endif

IMPORT os

&include "genero_lib1.inc"
&define L_DBGMSG( lev, msg ) \
IF msg IS NULL THEN \
	CALL l_dbgMsg( __FILE__, __LINE__, lev, "NULL!") \
ELSE \
	CALL l_dbgMsg( __FILE__, __LINE__, lev, msg ) \
END IF\

PUBLIC DEFINE
	r_preview INTEGER,
	r_interactive,m_setup_done BOOLEAN

TYPE t_opts RECORD
	r_filename STRING, -- name .4rp	r_output STRING,
	r_orientation CHAR(1),  -- only for ASCII reports.
	r_output STRING,
	r_grwsvgserver STRING,
	r_action STRING,
	r_outputFileName STRING,
	r_printer SMALLINT,
	r_confirmation BOOLEAN,
	r_outDataOnly BOOLEAN
	END RECORD 

PUBLIC DEFINE opts t_opts -- public variable

PRIVATE DEFINE p_opts t_opts -- previous values, used in dialog

DEFINE m_printers DYNAMIC ARRAY OF RECORD
		name STRING,
		default BOOLEAN
	END RECORD
DEFINE m_def_printer SMALLINT
DEFINE m_rptDir STRING
--------------------------------------------------------------------------------
#+ Set the Configuration for the report output.
#+
#+ @param l_fileName ASCII or report template name
#+ @param l_device XML/SVG/PDF/XLS/HTML/Image/Printer Default=ARG_VAL(1)
#+ @param l_preview TRUE/FALSE Default=TRUE
#+ @param l_targetName File / Printer name Default=ARG_VAL(2)
#+ @param l_ori L/P landscape / portrait  Default=L
#+ @param l_interactive Interactive
#+ @return none
--TODO: Error handling/messages
FUNCTION glGRW_setOptions(l_fileName, l_device, l_preview, l_targetName, l_ori, l_interactive)
	DEFINE l_fileName, l_device, l_targetName, l_ori STRING
	DEFINE l_preview,l_interactive BOOLEAN
GL_MODULE_ERROR_HANDLER
	LET opts.r_filename = l_fileName
	LET opts.r_output = l_device
	IF l_preview THEN 
		LET opts.r_action = "preview"
	ELSE
		LET opts.r_action = "save"
	END IF
	LET opts.r_outputFileName = l_targetName
	LET opts.r_orientation = l_ori
	LET r_interactive = l_interactive
&ifdef gotJAVA
	CALL glGRW_getPrinterListJAVA()
&else
	CALL glGRW_getPrinterList()
&endif
	LET opts.r_printer = m_def_printer
	IF opts.r_output = "Printer" AND opts.r_outputFileName IS NOT NULL THEN
		LET opts.r_printer = opts.r_outputFileName
	END IF
	LET m_setup_done = TRUE
END FUNCTION
--------------------------------------------------------------------------------
#+ Select the output destination - SVG / PDF
#+
#+ @param r_filename Default file name
#+ @return Sax handler or NULL
FUNCTION glGRW_rptStart(l_filename)
	DEFINE l_filename,  l_imagePath STRING
	DEFINE l_handler om.saxdocumenthandler
	DEFINE l_f ui.form
	DEFINE l_w ui.Window
	DEFINE x SMALLINT

	LET INT_FLAG = FALSE

	IF NOT m_setup_done THEN
		LET r_interactive = TRUE
		LET opts.r_action = "preview"
		LET opts.r_outDataOnly = FALSE
		LET opts.r_confirmation = FALSE
		LET opts.r_filename = l_filename
		IF NUM_ARGS() > 1 THEN LET opts.r_output = ARG_VAL(2) END IF
		IF NUM_ARGS() > 2 THEN LET opts.r_action = ARG_VAL(3) END IF
		IF NUM_ARGS() > 3 THEN LET r_interactive = ARG_VAL(4) END IF
		IF NUM_ARGS() > 4 THEN LET opts.r_outputFileName = ARG_VAL(5) END IF
		IF opts.r_output = "ASCII" THEN RETURN NULL END IF

&ifdef gotJAVA
		CALL glGRW_getPrinterListJAVA()
&else
		CALL glGRW_getPrinterList()
&endif
		LET opts.r_printer = m_def_printer
		IF opts.r_output = "Printer" AND opts.r_outputFileName IS NOT NULL THEN
			LET opts.r_printer = opts.r_outputFileName
		END IF
	END IF

	IF opts.r_orientation IS NULL THEN LET opts.r_orientation = "L" END IF
	IF opts.r_output IS NULL THEN LET opts.r_output = "SVG" END IF
	LET opts.r_grwsvgserver = fgl_getEnv("GRWSVGSERVER")
	IF opts.r_grwsvgserver IS NULL OR opts.r_grwsvgserver.getLength() < 1 THEN
		LET opts.r_grwsvgserver = fgl_getEnv("FGLSERVER")
	END IF
	IF opts.r_output = "XML" THEN LET opts.r_outDataOnly = TRUE END IF
	DISPLAY "Report:",opts.r_filename,":",opts.r_output,":",opts.r_outputFileName

	LET m_rptDir = fgl_getEnv("REPORTDIR")
	LET l_imagePath = fgl_getEnv("FGLIMAGEPATH") -- ".."||os.path.separator()||"etc"||os.path.separator()
	LET x = l_imagePath.getIndexOf(":",2)
	IF x > 0 THEN
		LET l_imagePath = l_imagePath.subString(1,x-1)||os.path.separator()
	END IF

	IF r_interactive THEN
		OPTIONS INPUT WRAP
		LET l_w = ui.window.getCurrent()
		IF l_w.gettext() IS NULL THEN
			CLOSE WINDOW SCREEN
		END IF
		OPEN WINDOW config WITH FORM "gl_grwCfg"
		DISPLAY "Open window"
		CALL ui.Interface.refresh()
		DISPLAY "After refresh"

		CALL fgl_setTitle( os.path.rootname( ARG_VAL(0) )||" - Configuration" )
		IF opts.r_fileName = "ASCII" THEN
			DISPLAY "ascii_"||opts.r_orientation TO preview
		ELSE
			IF os.path.exists( os.path.rootName( l_imagePath||opts.r_filename )||".jpg" ) THEN
				DISPLAY os.path.rootName( opts.r_filename )||".jpg" TO preview
			ELSE
				DISPLAY "nopreview" TO preview
			END IF

			IF NOT os.path.exists( m_rptDir||opts.r_filename ) THEN
				CALL fgl_winMessage(%"Error",SFMT(%"%1 Doesn't Exist",m_rptDir||opts.r_filename),"exclamation")
			END IF
		END IF

		INPUT BY NAME opts.* ATTRIBUTE(WITHOUT DEFAULTS,UNBUFFERED)
			BEFORE INPUT
				LET l_f = DIALOG.getForm()
				LET p_opts.* = opts.*
				DISPLAY "Output:",opts.r_output
				IF l_fileName = "ASCII" THEN
					CALL DIALOG.setFieldActive("r_filename",FALSE)
				ELSE
					CALL l_f.setElementHidden("formonly.r_orientation",TRUE)
				END IF
				CALL DIALOG.setFieldActive("r_outputfilename",FALSE)
				DISPLAY "Before input."
			ON CHANGE r_filename
				IF os.path.exists( os.path.rootName( l_imagePath||opts.r_filename )||".jpg" ) THEN
					DISPLAY os.path.rootName( opts.r_filename )||".jpg" TO preview
				ELSE
					DISPLAY "nopreview" TO preview
				END IF
			ON CHANGE r_orientation
				DISPLAY "ascii_"||opts.r_orientation TO preview
			ON CHANGE r_output
				CALL DIALOG.setfieldactive("r_grwsvgserver",FALSE)
				CALL DIALOG.setfieldactive("r_action",TRUE)
				CALL l_f.setElementHidden("formonly.r_outputfilename",FALSE)
				CALL l_f.setElementHidden("l_filename",FALSE)
				CALL l_f.setElementHidden("formonly.r_printer",TRUE)
				CALL l_f.setElementHidden("l_prnname",TRUE)
				CASE opts.r_output
					WHEN "SVG"
						CALL DIALOG.setfieldactive("r_grwsvgserver",TRUE)

					WHEN "Printer"
						IF m_def_printer = 0 THEN
							CALL fgl_winMessage("Error", "No Printers found.","exclamation")
						END IF
						CALL DIALOG.setfieldactive("r_action",FALSE)
						CALL l_f.setElementHidden("formonly.r_outputfilename",TRUE)
						CALL l_f.setElementHidden("l_filename",TRUE)
						CALL l_f.setElementHidden("formonly.r_printer",FALSE)
						CALL l_f.setElementHidden("l_prnname",FALSE)
						LET opts.r_action = "print"
						LET opts.r_outputFileName = NULL
					WHEN "Image"
						CALL DIALOG.setfieldactive("r_action",FALSE)
				END CASE
				CALL glGRW_setFileExt()
			ON CHANGE r_action
				CASE opts.r_action
					WHEN "preview"
						CALL DIALOG.setFieldActive("r_outputfilename",FALSE)
					OTHERWISE
						IF opts.r_outputFileName IS NULL THEN 
							LET opts.r_outputFileName = os.path.rootName( opts.r_filename )
							CALL glGRW_setFileExt()
						END IF
						CALL DIALOG.setFieldActive("r_outputfilename",TRUE)
				END CASE
			ON CHANGE r_outDataOnly
				IF NOT opts.r_outDataOnly THEN
					LET opts.* = p_opts.*
					LET opts.r_outDataOnly = FALSE
					IF opts.r_filename != "ASCII" THEN CALL DIALOG.setFieldActive("r_filename",TRUE) END IF
					CALL DIALOG.setFieldActive("r_output",TRUE)
					CALL DIALOG.setFieldActive("r_action",TRUE)
					CALL DIALOG.setFieldActive("r_grwsvgserver",TRUE)
				ELSE
					LET p_opts.* = opts.*
					LET opts.r_outDataOnly = TRUE
					LET opts.r_output = "Image"
					LET opts.r_action = "save"
					IF opts.r_outputFileName IS NULL THEN
						LET opts.r_outputFileName = base.Application.getProgramName()||".xml"
					END IF
					CALL DIALOG.setFieldActive("r_outputfilename",TRUE)
					CALL DIALOG.setFieldActive("r_filename",FALSE)
					CALL DIALOG.setFieldActive("r_output",FALSE)
					CALL DIALOG.setFieldActive("r_action",FALSE)
					CALL DIALOG.setFieldActive("r_grwsvgserver",FALSE)
				END IF
			ON ACTION CLOSE	EXIT INPUT
		END INPUT
		IF INT_FLAG THEN
&ifdef GL
			IF gl_winQuestion("Quit","Exit Program?","Y","Yes|No","question") = "Yes" THEN
&else
			IF fgl_winQuestion("Quit","Exit Program?","Y","Yes|No","question",0) = "Yes" THEN
&endif
				CLOSE WINDOW config
				EXIT PROGRAM
			END IF
			L_DBGMSG(0,  "Report cancelled." )
			CLOSE WINDOW config
			RETURN NULL 
		END IF
	END IF

	IF opts.r_filename != "ASCII" AND NOT os.path.exists( m_rptDir||opts.r_filename ) THEN
		CALL gl_winMessage("Error",SFMT(%"The Report Does not exist\n%1",opts.r_filename),"exclamation")
		L_DBGMSG(0,  "Report aborted!" )
		RETURN NULL
	END IF

	IF opts.r_output = "Image" THEN
		LET opts.r_action = "save"
	END IF

	IF opts.r_action = "preview" THEN
		LET r_preview = TRUE
	END IF

	IF opts.r_outDataOnly THEN
		LET r_preview = FALSE
	END IF

	CALL fgl_setEnv("GRWSVGSERVER", opts.r_grwsvgserver)

	L_DBGMSG(3,  "Output:"||m_rptDir||opts.r_filename||" Method:"||opts.r_output||" Preview:"||opts.r_action )

	-- load the 4rp file
	IF opts.r_filename != "ASCII" THEN
		IF NOT fgl_report_loadCurrentSettings(m_rptDir||opts.r_filename) THEN
			CALL gl_winMessage(%"Error",SFMT(%"fgl_report_loadCurrentSettings(%1) Failed!",opts.r_filename),"exclamation")
			RETURN NULL
		END IF
	ELSE
		IF NOT fgl_report_loadCurrentSettings(NULL) THEN
			CALL gl_winMessage(%"Error",%"fgl_report_loadCurrentSettings NULL Failed!","exclamation")
			RETURN NULL
		END IF
		IF opts.r_orientation = "L" THEN
			CALL fgl_report_configurePageSize("a4length","a4width")
		ELSE
			CALL fgl_report_configurePageSize("a4width","a4length")
		END IF
	END IF

	CALL fgl_report_selectDevice(opts.r_output)
	CALL fgl_report_selectPreview(r_preview)
	IF opts.r_outputFileName IS NOT NULL THEN
		CALL fgl_report_setOutputFileName( opts.r_outputFileName )
	END IF
	IF opts.r_output = "Printer" AND opts.r_printer != m_def_printer THEN
		CALL fgl_report_setPrinterName( m_printers[ opts.r_printer ].name )
	END IF

	IF opts.r_outDataOnly THEN -- output xml debug data only.
		LET l_handler = fgl_report_createProcessLevelDataFile(opts.r_outputFileName)
	ELSE	-- commit changed parameters
		LET l_handler = fgl_report_commitCurrentSettings()
	END IF
	IF l_handler IS NULL THEN
		CALL gl_winMessage(%"Error",%"fgl_report_commitCurrentSettings Failed!","exclamation")
	END IF
	RETURN l_handler
END FUNCTION 
--------------------------------------------------------------------------------
#+ Start a plain ASCII report.
#+
#+ @param l_device SVG/PDF/Image/Printer Default=ARG_VAL(1)
#+ @param l_preview TRUE/FALSE Default=TRUE
#+ @param l_targetName File / Printer name Default=ARG_VAL(2)
#+ @param l_ori L/P landscape / portrait  Default=L
#+ @return Sax handler or NULL
--TODO: Error handling/messages
FUNCTION glGRW_rptStartASCII(l_device, l_preview, l_targetName, l_ori)
	DEFINE l_device, l_preview, l_targetName, l_ori STRING

	IF l_device IS NULL THEN LET l_device = ARG_VAL(1) END IF
	IF l_preview IS NULL THEN LET l_preview = TRUE END IF
	IF l_targetName IS NULL THEN LET l_targetName = ARG_VAL(2) END IF
	IF l_ori IS NULL THEN LET l_ori = "L" END IF

	IF l_device = "ASCII" THEN RETURN TRUE END IF

	IF NOT fgl_report_loadCurrentSettings(NULL) THEN
		RETURN FALSE
	END IF
-- Don't want multiple pages to one page!
--	CALL fgl_report_selectLogicalPageMapping("multipage")

-- 2 page count
-- 4 ISOA4
-- TRUE portrait / FALSE landscape
-- TODO: Parameters for these values
--	CALL fgl_report_configureMultipageOutput(1, 4, FALSE)

-- Landscape/Portrait
	IF l_ori = "L" THEN
		CALL fgl_report_configurePageSize("a4length","a4width")
	ELSE
		CALL fgl_report_configurePageSize("a4width","a4length")
	END IF

	IF l_device != "XML" THEN
		CALL fgl_report_selectDevice(l_device)
		CALL fgl_report_selectPreview(l_preview)
	END IF

	IF l_device = "Printer" THEN
		CALL fgl_report_setPrinterName( l_targetName )
	ELSE
		IF l_targetName IS NOT NULL THEN
			CALL fgl_report_setOutputFileName( l_targetName )
		END IF
	END IF
-- Return the SAX handler
	IF l_device = "XML" THEN
		RETURN fgl_report_createProcessLevelDataFile(l_targetName)
	ELSE
		RETURN fgl_report_commitCurrentSettings()
	END IF

END FUNCTION 
--------------------------------------------------------------------------------
#+ Printing Window with message...
#+
#+ @param mode 1=Open 2=Close
FUNCTION glGRW_printMessage(mode,txt)
	DEFINE mode INTEGER
	DEFINE txt STRING
	DEFINE winnode, frm, g, lab om.DomNode
	DEFINE w ui.window
	DEFINE f ui.Form

	IF mode = 1 THEN
		OPEN WINDOW mess WITH 1 ROWS, 50 COLUMNS
		LET w = ui.window.getcurrent()
		LET winnode = w.getnode()
		CALL winnode.setAttribute("style","naked")
		CALL winnode.setAttribute("width",45)
		CALL winnode.setAttribute("height",2)
		CALL winnode.setAttribute("text",txt)

		LET f = w.createform("message")
		LET frm = f.getnode()
		CALL frm.setAttribute("text","ProgressBar")

		LET g = frm.createChild('Grid')

		LET lab = g.createChild('Label')
		CALL lab.setAttribute("text", txt)
	ELSE
		CLOSE WINDOW mess
	END IF
	CALL ui.interface.refresh()
END FUNCTION
--------------------------------------------------------------------------------
#+ Call on completion of report.
#+
#+ @param rows_read Number of Rows Output to report.
FUNCTION glGRW_rptFinish(rows_read)
	DEFINE rows_read INTEGER

	IF rows_read > 0 AND opts.r_output = 'PDF' AND NOT r_preview THEN
		CALL glGRW_savePDF()
	END IF

	DISPLAY "Report Finished, printed ",rows_read," rows."

	L_DBGMSG(3,  "Report Finished, printed "||rows_read||" rows." )
	IF opts.r_confirmation THEN
		CALL glGRW_printMessage(1,SFMT(%"%1 Rows Printed", rows_read))
		MENU
			ON ACTION close EXIT MENU
		END MENU
		CALL glGRW_printMessage(0,NULL)
	END IF

END FUNCTION 
--------------------------------------------------------------------------------
#+ Display the Error from the SQL
#+
FUNCTION glGRW_getUser()
	DEFINE usr STRING
	LET usr = fgl_getEnv("LOGNAME")
	IF usr IS NULL THEN LET usr = fgl_getEnv("USERNAME") END IF
	RETURN usr
END FUNCTION 
--------------------------------------------------------------------------------
#+ Display the Error from the SQL
#+
#+ @param msg Error message.
FUNCTION glGRW_sqlErr(msg, db_name)
	DEFINE msg, db_name, dbi, val String

	LET msg = msg.append("\n"||SQLERRMESSAGE)
	LET msg = msg.append("\n"||"FGLPROFILE="||fgl_getEnv("FGLPROFILE"))
	LET dbi = "dbi.database."||db_name||".driver"
	LET val = base.application.getResourceEntry( dbi )
	IF val.getLength() < 1 THEN LET val = "(null)" END IF
	LET msg = msg.append( "\n"||dbi||"="||val )
	LET dbi = "dbi.database."||db_name||".source"
	LET val = base.application.getResourceEntry( dbi )
	IF val.getLength() < 1 THEN LET val = "(null)" END IF
	LET msg = msg.append( "\n"||dbi||"="||val )
	CALL fgl_winMessage(%"Error", msg,"exclamation")

END FUNCTION
--------------------------------------------------------------------------------
#+ Save the PDF to the Client machine
#+
FUNCTION glGRW_savePDF()
	DEFINE filename STRING

	CALL ui.interface.frontcall("standard","savefile",[ "", "PDF","*.pdf",%"Save the Report"], filename)
	IF filename IS NULL THEN RETURN END IF

	CALL fgl_putFile( "report.pdf", filename )
	
END FUNCTION
--------------------------------------------------------------------------------
#+ Populate the file combo for the list of reports.
#+
#+ @param cb ui.combobox object passed by default initializer.
FUNCTION glGRW_fileCombo( cb )
	DEFINE cb ui.combobox
	DEFINE fullname, l_filename STRING
	DEFINE x SMALLINT

	LET fullname = opts.r_filename
	LET l_filename = os.path.rootname(opts.r_filename) -- remove extension

--	DISPLAY "fullname:",fullname," r_filename:",opts.r_filename," l_filename:",l_filename
	CALL cb.additem( fullname ,l_filename)

-- TODO: this is quick way to get multiple reports.
	LET x = 1
	WHILE TRUE
		LET fullname = l_filename||"-"||x||".4rp" -- Add path
		IF os.path.exists( m_rptDir||fullname ) THEN
			CALL cb.additem( fullname ,l_filename||"-"||x )
			LET x = x + 1
		ELSE
			EXIT WHILE
		END IF
	END WHILE

END FUNCTION
--------------------------------------------------------------------------------
#+ Populate the printer combo for the list of server side printers.
#+
#+ @param cb ui.combobox object passed by default initializer.
FUNCTION glGRW_prnCombo( cb )
	DEFINE cb ui.combobox
	DEFINE x SMALLINT

	CALL cb.clear()

	FOR x = 1 TO m_printers.getLength()
		IF m_printers[x].default THEN
			CALL cb.additem( x, m_printers[x].name||"(Default)" )
		ELSE
			CALL cb.additem( x, m_printers[x].name )

		END IF
	END FOR

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION glGRW_setFileExt()
	DEFINE l_ext STRING
	LET l_ext = "."||DOWNSHIFT(opts.r_output)
	IF opts.r_output = "Image" THEN LET l_ext = ".jpg" END IF
	IF os.path.extension( opts.r_outputFileName ) != l_ext THEN
		LET opts.r_outputFileName = os.path.rootName( opts.r_outputFileName )||l_ext
	END IF
END FUNCTION
--------------------------------------------------------------------------------
#+ Display debug messages to console.
#+
#+ @param fil __FILE__ - File name
#+ @param lno __LINE__ - Line Number
#+ @param lev Level of debug
#+ @param msg Message
#+ @return Nothing.
FUNCTION l_dbgMsg(fil, lno, lev, msg) --{{{
	DEFINE fil STRING
	DEFINE lno INTEGER
	DEFINE msg STRING
	DEFINE lev,l_dbglev SMALLINT
	DEFINE lin CHAR(22)
	DEFINE x SMALLINT

	LET l_dbgLev = fgl_getEnv("FJS_GL_DBGLEV")

	IF l_dbgLev = 0 AND lev = 0 THEN
		DISPLAY base.application.getprogramname(), ":",msg.trim()
	ELSE
		IF l_dbgLev >= lev THEN
			LET x = fil.getIndexOf(".",1)
			LET fil = fil.subString(1,x-1)
			LET lin = "...............:",lno USING "##,###"
			LET x = fil.getLength()
			IF x > 22 THEN LET x = 22 END IF
			LET lin[1,x] = fil.trim()
			DISPLAY lin,":",lev USING "<<&",": ",msg.trim()
			CALL ERRORLOG(lin||":"||(lev USING "<<&")||": "||msg.trim())
		END IF
	END IF
END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Get Printer List Java Version
&ifdef gotJAVA
FUNCTION glGRW_getPrinterListJava()
	DEFINE pras javax.print.attribute.PrintRequestAttributeSet
	DEFINE pss ARRAY [] OF javax.print.PrintService
	DEFINE df DocFlavor
	DEFINE p,x SMALLINT
	DEFINE line STRING

	DISPLAY "Java - Retrieving Printer List..."
	LET pras = HashPrintRequestAttributeSet.create()
	CALL pras.add( Copies.create(1) )

	LET pss = PrintServiceLookup.lookupPrintServices( df , pras)

	IF pss.getLength() = 0 THEN
		LET m_def_printer = 0
		DISPLAY "No Printers!"
		RETURN
	ELSE
		CALL m_printers.clear()
		FOR p = 1 TO pss.getLength()
			LET line = pss[p].toString()
			LET x = line.getIndexOf(":",10)
			LET m_printers[ m_printers.getLength() + 1 ].name = line.subString(x+2,line.getLength())
			IF p = 1 THEN LET m_printers[ m_printers.getLength() ].default = TRUE END IF
			DISPLAY "p:",m_printers[ m_printers.getLength() ].name, " :",m_printers[ m_printers.getLength() ].default
		END FOR
	END IF
	LET m_def_printer = 1
	DISPLAY "Done."
END FUNCTION --}}}
&endif
--------------------------------------------------------------------------------
#+ Get Printer List
FUNCTION glGRW_getPrinterList() --{{{
	DEFINE c base.channel
	DEFINE cmd, line STRING
	DEFINE x SMALLINT
	CALL m_printers.clear()

	LET c = base.channel.create()

	IF os.path.separator() = "/" THEN -- Linux/Unix
		LET cmd = "cat printers_lnx.txt" -- Need a real solution !!!
	ELSE
		LET cmd = "cscript printers_win32.vbs"
	END IF

	DISPLAY "Retrieving Printer List..."
	CALL c.openpipe( cmd, "r" )
	WHILE NOT c.isEof()
		LET line = c.readLine()
		IF line.subString(1,8) = "Printer:" THEN
			IF line.getIndexOf("\\",1) > 0 THEN
				LET line = glGRW_doubleslash( line )
			END IF
			LET x = line.getIndexOf(":",10)
			LET m_printers[ m_printers.getLength() + 1 ].name = line.subString(10,x-1)
			IF line.getCharAt(x+1) = "T" THEN LET m_printers[ m_printers.getLength() ].default = TRUE END IF
			DISPLAY "p:",m_printers[ m_printers.getLength() ].name, " :",m_printers[ m_printers.getLength() ].default
			IF m_printers[ m_printers.getLength() ].default THEN
				LET m_def_printer = m_printers.getLength()
			END IF
		END IF
	END WHILE
	DISPLAY "Done."

END FUNCTION --}}}
--------------------------------------------------------------------------------
FUNCTION glGRW_doubleslash( line )
	DEFINE line, newline STRING
	DEFINE x SMALLINT

	FOR x = 1 TO line.getLength()
		LET newline = newline,line.getCharAt(x)
		IF line.getCharAt(x) = "\\" THEN LET newline = newline,"\\" END IF
	END FOR
	RETURN newline.trim()
END FUNCTION --}}}
