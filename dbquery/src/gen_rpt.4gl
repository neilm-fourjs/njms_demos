
{ CVS Header
$Author: test4j $
$Date: 2007/07/12 16:42:43 $
$Revision: 208 $
$Source: /usr/home/test4j/cvs/all/demos/dbquery/src/gen_rpt.4gl,v $
$Log: gen_rpt.4gl,v $
Revision 1.18  2007/07/12 16:42:43  test4j

Changes for built in precompiler

Revision 1.17  2006/07/21 11:34:25  test4j

restructures make

Revision 1.16  2005/11/14 17:08:23  test4j

remove functions from lib.4gl that are in genero_lib1.4gl and changed other
files to call the standard library code.

Revision 1.15  2005/11/14 16:55:30  test4j

Changed to use standard library code.

Revision 1.14  2005/07/27 17:48:04  test4j

fixed bug when table has 24 columns.

Revision 1.13  2005/05/10 14:42:35  test4j

CVS header added.

}

-- WARNING: this requires PrintClient to be installed.

-- CALL gen_rpt ( tabnam, cols, ftyp, wher )
-- tabnam = table name
-- cols = columns names up to MAX_COLS
-- ftyp = types of columns D=Date, C=Char, N=Numeric/Decimal, I=Integer
-- wher = The WHERE clause, 1=1 means all, or use result of construnct

&include "dbquery.inc" 

-- NOTE: ADDFLD(l,x,f,e,w) is now defined in dbquery.inc

	DEFINE driver om.SaxDocumentHandler
	DEFINE a om.SaxAttributes

	DEFINE cf ARRAY[MAX_LST_COLS] OF CHAR(MAX_COL_LEN)
	 
	DEFINE data_ar ARRAY [MAX_LST_COLS] OF RECORD
		cf CHAR(MAX_COL_LEN),
		if INTEGER,
		nf DECIMAL(10,2),
		df DATE
	END RECORD
	DEFINE recs INTEGER
	DEFINE col_ar DYNAMIC ARRAY OF CHAR(18)
	DEFINE space CHAR(1)
	DEFINE col_cnt,x SMALLINT
	DEFINE prncli SMALLINT
	DEFINE col_len ARRAY[MAX_LST_COLS] OF SMALLINT

FUNCTION gen_rpt( tabnam, cols, ftyp, wher, l_prncli )
	DEFINE tabnam, cols,wher STRING
	DEFINE ftyp CHAR(MAX_LST_COLS)
	DEFINE l_prncli SMALLINT
	DEFINE wwin ui.Window
	DEFINE ffrm ui.Form
	DEFINE win, frm, grid, tabl, tabc, edit	om.DomNode
	DEFINE hb,sp,titl om.DomNode
	DEFINE fn CHAR(4)
	DEFINE tot_recs,i,startIndex,bufferLength INTEGER
	DEFINE tok base.StringTokenizer
	DEFINE ttyp CHAR(1)
	DEFINE tlen SMALLINT
	DEFINE hd RECORD 
							fld1 CHAR(20),
							fld2 CHAR(20),
							fld3 CHAR(20),
							fld4 CHAR(20),
							fld5 CHAR(20),
							fld6 CHAR(20)
	END RECORD

	DEFINE listhead RECORD
		company_name String,
		user_name String,
		list_title String,
		list_description String,
		list_date String
	END RECORD
	DEFINE xml_col ARRAY[MAX_LST_COLS] OF om.domNode
	DEFINE do_dyn_rpt,canl SMALLINT

	LET prncli = l_prncli

-- Check to make sure there are records.
	PREPARE rpt_cntpre FROM "SELECT COUNT(*) FROM "||tabnam||" WHERE "||wher
	DECLARE rpt_cntcur CURSOR FOR rpt_cntpre
	OPEN rpt_cntcur
	FETCH rpt_cntcur INTO tot_recs
	CLOSE rpt_cntcur
	IF tot_recs < 1 THEN
		CALL fgl_winmessage("Error", "No Records Found", "exclamation")
		RETURN
	END IF

-- Break column list into columns for table headings
	LET tok = base.StringTokenizer.create( cols, "," )
	LET col_cnt = 1
	WHILE tok.hasMoreTokens()
		LET col_ar[col_cnt] = tok.nextToken()
		LET col_cnt = col_cnt + 1
	END WHILE
	LET col_cnt = col_cnt - 1

-- Get column length from xml schema + take biggest: colname or collenght
	FOR x = 1 TO col_cnt
		LET xml_col[x] = gl_findXmlCol(tabnam,col_ar[x],xml_root)
		LET col_len[x] = xml_col[x].getAttribute("collen")
		IF col_len[x] < LENGTH(col_ar[x]) THEN
			LET col_len[x] = LENGTH(col_ar[x])
		END IF
	END FOR

	LET listhead.company_name="Four J's Development Tools"
	LET listhead.user_name=fgl_getenv("LOGNAME")
	LET listhead.list_title=tabnam
	LET listhead.list_description="Generated report for table:"||tabnam
	LET listhead.list_date=TODAY USING "dd/mm/yyyy"

-- Prepare/Declare main cursor
	PREPARE rpt_pre FROM "SELECT "||cols||" FROM "||tabnam||" WHERE "||wher
	DECLARE rpt_cur SCROLL CURSOR FOR rpt_pre

	CALL get_prn_opts() RETURNING canl,prn_opts.*
	IF canl THEN RETURN END IF

	LET do_dyn_rpt = FALSE
        { Taken out 
	IF prncli THEN
		LET do_dyn_rpt = TRUE
		CALL gen_cfg(prn_opts.*)
		CALL gen_grf()
		LET driver = configureReportPipeFromFile("gen_rpt.cfg") -- generated grf
--		LET driver = om.XmlWriter.createFileWriter("report.xml") -- xml report
--		LET driver = configureReportPipeFromFile("xml.cfg")	-- for REPORT ONLY
	END IF
        }
	IF do_dyn_rpt THEN
		CALL driver.startDocument()
		LET a=om.SaxAttributes.create()

-- Default print options
		CALL a.addAttribute("headerLength",prn_opts.head_len)
		CALL a.addAttribute("tailerLength",prn_opts.tail_len)
		CALL a.addAttribute("pageLength",prn_opts.page_len)
		CALL a.addAttribute("topMargin",prn_opts.margin_t)
		CALL a.addAttribute("bottomMargin",prn_opts.margin_b)
		CALL a.addAttribute("leftMargin",prn_opts.margin_l)
		CALL a.addAttribute("rightMargin",prn_opts.margin_r)
		CALL a.addAttribute("to",prn_opts.destinat)
		CALL a.addAttribute("fileName",prn_opts.filename)
		CALL driver.startElement("Report",a)

		CALL a.clear()
		CALL driver.startElement("FirstPageHeader",a)

-- Standard Heading
		CALL a.clear()
		CALL a.addAttribute("name","stdheader")
		CALL driver.startElement("Print",a)
		CALL do_line("company_name",listhead.company_name,30)
		CALL do_line("user_name",listhead.user_name,12)
		CALL do_line("list_title",listhead.list_title,30)
		CALL do_line("list_description",listhead.list_description,30)
		CALL do_line("list_date",listhead.list_date,10)
		CALL driver.endElement("Print")

-- Detail Headings
		CALL a.clear()
		CALL a.addAttribute("name","tableheader")
		CALL driver.startElement("Print",a)
		FOR x = 1 TO col_cnt
			CALL do_line(col_ar[x],col_ar[x],col_len[x])
		END FOR
		CALL driver.endElement("Print")
		CALL driver.endElement("FirstPageHeader")
	
-- Detail
		FOREACH rpt_cur INTO cf[1],cf[2],cf[3],cf[4],cf[5],cf[6]					
			CALL a.clear()
			CALL a.addAttribute("name","tabledata")
			CALL driver.startElement("Print",a)
			FOR x = 1 TO col_cnt
					CALL do_line(col_ar[x],cf[x],col_len[x])
			END FOR
			CALL driver.endElement("Print")
		END FOREACH
		CALL driver.endElement("Report")
		CALL driver.endDocument()
	ELSE
		LET hd.fld1 = col_ar[1]
		LET hd.fld2 = col_ar[2]
		LET hd.fld3 = col_ar[3]
		LET hd.fld4 = col_ar[4]
		LET hd.fld5 = col_ar[5]
		LET hd.fld6 = col_ar[6]
		IF prn_opts.destinat = "file" THEN
			START REPORT my_rpt TO FILE prn_opts.filename
		ELSE
			START REPORT my_rpt TO PRINTER
		END IF
		FOREACH rpt_cur INTO cf[1],cf[2],cf[3],cf[4],cf[5],cf[6]					
			OUTPUT TO REPORT my_rpt( hd.*,listhead.* )
		END FOREACH			 
		FINISH REPORT my_rpt	
	END IF

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION gen_cfg()
	DEFINE cfg_doc om.domDocument
	DEFINE cfg_root,cfg om.domNode

	LET cfg_doc = om.domdocument.create("PIPE")
	LET cfg_root = cfg_doc.getdocumentelement()
	LET cfg = cfg_root.createChild("GrfStyleSheet")
	CALL cfg.setAttribute("grfFileName","gen_rpt.grf")
	CALL cfg.setAttribute("compat","0")

	LET cfg = cfg_root.createChild("PrettyPrinterStyleSheet")
	CALL cfg.setAttribute("tee","false")
	CALL cfg.setAttribute("writeToProgram","java StyleSheetMain -stdin")

	LET cfg = cfg_root.createChild("PxmlLayouter")
	CALL cfg.setAttribute("pageWidth",prn_opts.paper_wd)
	CALL cfg.setAttribute("pageHeight",prn_opts.paper_ht)
	CALL cfg.setAttribute("topMargin",prn_opts.margin_t)
	CALL cfg.setAttribute("leftMargin",prn_opts.margin_l)
	CALL cfg.setAttribute("rightMargin",prn_opts.margin_r)
	CALL cfg.setAttribute("bottomMargin",prn_opts.margin_b)

	LET cfg = cfg_root.createChild(prn_opts.final_ou)
	IF prn_opts.final_ou = "PdfWriterStyleSheet" THEN
		CALL cfg.setAttribute("writeToFile",prn_opts.filename)
	END IF

	CALL cfg_root.writeXML("gen_rpt.cfg")
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION gen_grf()
	DEFINE grf_doc om.domDocument
	DEFINE grf_root,grf,grf_str om.domNode

	LET grf_doc = om.domdocument.create("GRF")
	LET grf_root = grf_doc.getdocumentelement()
	CALL grf_root.setAttribute("pageWidth","max")
	CALL grf_root.setAttribute("pageLength","max")
	CALL grf_root.setAttribute("fontName","SansSerif")
	CALL grf_root.setAttribute("fontSize","10")
	LET grf = grf_root.createChild("IMPORT")
	CALL grf.setAttribute("grfFileName","list.grf")
	LET grf = grf_root.createChild("HEADER")
	CALL grf.setAttribute("type","any")
	LET grf = grf.createChild("MATCH")
	CALL grf.setAttribute("name","tableHeader")
	LET grf_str = grf.createChild("STRIPE")
--	CALL grf_str.setAttribute("fontStyle","bold")
	FOR x = 1 TO col_cnt
		LET grf = grf_str.createChild("TEXTBOX")
		CALL grf.setAttribute("text","@caption")
		CALL grf.setAttribute("typebox","both")
		CALL grf.setAttribute("itemNo",x)
		LET grf = grf_str.createChild("TEXTBOX")
		CALL grf.setAttribute("text"," ")
	END FOR
	LET grf = grf_root.createChild("BODY")
	CALL grf.setAttribute("type","any")
	LET grf = grf.createChild("MATCH")
	CALL grf.setAttribute("name","tableData")
	LET grf_str = grf.createChild("STRIPE")
	FOR x = 1 TO col_cnt
		LET grf = grf_str.createChild("TEXTBOX")
		CALL grf.setAttribute("typebox","both")
		CALL grf.setAttribute("itemNo",x)
		LET grf = grf_str.createChild("TEXTBOX")
		CALL grf.setAttribute("text"," ")
	END FOR
	CALL grf_root.writeXml("gen_rpt.grf")

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION do_line(n,f,l)
	DEFINE n STRING
	DEFINE f STRING
	DEFINE l SMALLINT

	CALL a.clear()
	CALL a.addAttribute("name",n.trim())
	CALL a.addAttribute("type","CHAR("||l||")")
	CALL a.addAttribute("value",f.trim())
	CALL driver.startElement("Item",a)
	CALL driver.endElement("Item")

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION get_prn_opts()
	DEFINE win, frm, grid, lb, ff, edit om.DomNode
	DEFINE cb ui.ComboBox

	OPEN WINDOW prn_opts AT 1,1 WITH 20 ROWS, 80 COLUMNS
	LET win = gl_getWinNode(NULL)
	CALL win.setAttribute("style","dialog")
	LET frm = gl_genForm("prn_opts")
	CALL frm.setAttribute("name","Set Printing Options")
	CALL win.setAttribute("text","Set Printing Options")
	LET grid = frm.createChild("VBox")
	LET grid = grid.createChild("Grid")
	CALL grid.setAttribute("height","10")

	IF prncli THEN
		ADDFLD("Paper Size",1,"paper_sz","ComboBox",10)
		LET cb = ui.ComboBox.forName("paper_sz")
		CALL cb.addItem("a4","A4")
		CALL cb.addItem("a5","A5")
		CALL cb.addItem("a3","A3")
		ADDFLD("Orientation",2,"paper_or","RadioGroup",12)
		LET lb = edit.createChild("Item")
		CALL lb.setAttribute("name","landscape")
		CALL lb.setAttribute("text","Landscape")
		LET lb = edit.createChild("Item")
		CALL lb.setAttribute("name","portrait")
		CALL lb.setAttribute("text","Portrait")
--		LET cb = ui.ComboBox.forName("paper_or")
--		CALL cb.addItem("landscape","Landscape")
--		CALL cb.addItem("portrait","Portrait")
	ELSE
		ADDFLD("Destination",1,"destinat","ComboBox",20)
		LET cb = ui.ComboBox.forName("destinat")
		CALL cb.addItem("file","File")
		CALL cb.addItem("printer","Printer")
		ADDFLD("Page Length",2,"page_len","Edit",10)
	END IF
	ADDFLD("Left Margin",3,"margin_l","Edit",10)
	ADDFLD("Right Margin",4,"margin_r","Edit",10)
	ADDFLD("Top Margin",5,"margin_t","Edit",10)
	ADDFLD("Bottom Margin",6,"margin_b","Edit",10)
	IF prncli THEN
		ADDFLD("Final Output",7,"final_ou","ComboBox",30)
		LET cb = ui.ComboBox.forName("final_ou")
		CALL cb.addItem("Viewer","Viewer")
		CALL cb.addItem("PdfWriterStyleSheet","PDF")
	ELSE
		ADDFLD("File Name",7,"filename","Edit",30)
	END IF

	LET prn_opts.page_len = 66
	IF prncli THEN
		LET prn_opts.margin_l = "1.5cm"
		LET prn_opts.margin_r = "1.5cm"
		LET prn_opts.margin_t = "1.5cm"
		LET prn_opts.margin_b = "1.5cm"
	ELSE
		LET prn_opts.margin_l = "2"
		LET prn_opts.margin_r = "2"
		LET prn_opts.margin_t = "2"
		LET prn_opts.margin_b = "2"
	END IF
	LET prn_opts.head_len = 4
	LET prn_opts.tail_len = 4
	LET prn_opts.paper_sz = "a4"
	LET prn_opts.paper_or = "portrait"
	LET prn_opts.destinat = "file"
	LET prn_opts.filename = "dbquery.rpt"
	LET prn_opts.final_ou = "Viewer"

	LET int_flag = FALSE
	IF prncli THEN
		INPUT BY NAME 
								prn_opts.paper_sz,
								prn_opts.paper_or,
								prn_opts.margin_l,
								prn_opts.margin_r,
								prn_opts.margin_t,
								prn_opts.margin_b,
								prn_opts.final_ou
			WITHOUT DEFAULTS
		IF prn_opts.final_ou = "PdfWriterStyleSheet" THEN
			LET prn_opts.filename = "dbquery.pdf"
		ELSE
			LET prn_opts.filename = "dbquery.rpt"
		END IF
	ELSE
		INPUT BY NAME 
								prn_opts.destinat,
								prn_opts.page_len,
								prn_opts.margin_l,
								prn_opts.margin_r,
								prn_opts.margin_t,
								prn_opts.margin_b,
								prn_opts.filename
			WITHOUT DEFAULTS
	END IF

	CLOSE WINDOW prn_opts
	IF int_flag THEN RETURN TRUE,prn_opts.* END IF

	CALL ui.interface.refresh()

	IF prn_opts.paper_or = "portrait" THEN
		LET prn_opts.paper_ht = prn_opts.paper_sz.trim()||"length"
		LET prn_opts.paper_wd = prn_opts.paper_sz.trim()||"width"
	ELSE
		LET prn_opts.paper_wd = prn_opts.paper_sz.trim()||"length"
		LET prn_opts.paper_ht = prn_opts.paper_sz.trim()||"width"
	END IF

	RETURN FALSE,prn_opts.*

END FUNCTION
--------------------------------------------------------------------------------
REPORT my_rpt(hd,listhead)
	DEFINE hd RECORD 
		fld1 CHAR(10),
		fld2 CHAR(10),
		fld3 CHAR(10),
		fld4 CHAR(10),
		fld5 CHAR(10),
		fld6 CHAR(10)
	END RECORD
	DEFINE listhead RECORD
		company_name String,
		user_name String,
		list_title String,
		list_description String,
		list_date String
	END RECORD
	DEFINE colhd CHAR(MAX_COL_LEN)
	DEFINE x,l SMALLINT
			 
	OUTPUT
			 PAGE LENGTH prn_opts.page_len
			 TOP MARGIN prn_opts.margin_t
			 BOTTOM MARGIN prn_opts.margin_b
			 LEFT MARGIN prn_opts.margin_l
			 RIGHT MARGIN prn_opts.margin_r
			 
	FORMAT
		FIRST PAGE HEADER
		IF prncli THEN
--			PRINTX name=stdHeader listhead.*
--			PRINTX name=tableHeader hd.*
			PRINT " "
		ELSE
			FOR x = 1 TO col_cnt
				LET colhd = col_ar[x]
				LET colhd[1] = UPSHIFT(colhd[1])
				PRINT colhd[1,col_len[x]]," ";
			END FOR
			PRINT " "
		END IF

		ON EVERY ROW
			IF prncli THEN
				PRINTX name=tableData cf[1],cf[2],cf[3],cf[4],cf[5],cf[6]
			ELSE
				FOR x = 1 TO col_cnt
					PRINT cf[x][1,col_len[x]]," ";
				END FOR
				PRINT " "
			END IF
				 
END REPORT
