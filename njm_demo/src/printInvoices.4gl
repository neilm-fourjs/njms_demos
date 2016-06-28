
#+ Order Printing
#+
#+ Arg 1 - SDI/MDI
#+ Arg 2 - userid
#+ Arg 3 - 0 / order number to print ( 0=all outstanding )
#+ Arg 4 - Report Layout to use
#+ Arg 5 - Output mode - SVG / PDF / PRINTER
#+ Arg 6 - preview / bg
#+ Arg 7 - Interactive True/False ( 1/0 )
#+ Arg 8 - output file name for Image/PDF
#+ eg: S 1 1 ordent.4rp SVG preview 1

IMPORT os

IMPORT FGL gl_grw

CONSTANT m_logo = "../pics/fourjs-demo-co.png"

&include "schema.inc"
&include "ordent.inc"
&include "genero_lib1.inc" -- Contains GL_DBGMSG & g_dbgLev

MAIN
	DEFINE l_row SMALLINT
	DEFINE l_stmt VARCHAR(200)
	DEFINE l_ordno INTEGER
	DEFINE l_rptStart BOOLEAN
	DEFINE l_report STRING
	DEFINE l_handler om.saxdocumenthandler
	DEFINE l_pack t_packItem
	DEFINE l_packcode CHAR(8)
	DEFINE l_pack_qty INTEGER

{
	RUN "env > "||ARG_VAL(1)||".env"
	CALL chk_libs("lib,libgre",".42x")
	CALL chk_libs("oe_lib,gl_lib,gl_db,gl_grw",".42m")
}
	LET gl_noToolBar = TRUE
	CALL gl_init(ARG_VAL(1),NULL,TRUE)
GL_MODULE_ERROR_HANDLER

	CALL gldb_connect(NULL)
	DISPLAY "Arg1:",ARG_VAL(1)," 2:",ARG_VAL(2)," 3:",ARG_VAL(3)," 4:",ARG_VAL(4)
	LET l_report = ARG_VAL(4)
	LET gl_grw.opts.r_fileName = l_report
	LET gl_grw.opts.r_output = ARG_VAL(5) --"PDF"
	LET gl_grw.opts.r_action = ARG_VAL(6)
	LET gl_grw.r_interactive = ARG_VAL(7) -- FALSE
	LET gl_grw.opts.r_outputFileName = ARG_VAL(8)
	LET gl_grw.m_setup_done = TRUE
	IF gl_grw.r_interactive IS NULL THEN
		LET gl_grw.r_interactive = TRUE
	END IF
	IF gl_grw.opts.r_output.getLength() < 2 THEN
		LET gl_grw.opts.r_output = "PDF"
	END IF
	IF gl_grw.opts.r_action.getLength() < 2 THEN
		LET gl_grw.opts.r_action = "preview"
	END IF

	TRY
		LET l_ordno = ARG_VAL(3)
	CATCH
		LET l_ordno = NULL
	END TRY
	DISPLAY "l_ordNo:",l_ordno
	LET m_user.username = glGRW_getUser()
	LET l_stmt = "SELECT * FROM ord_head "
	IF l_ordno IS NOT NULL AND l_ordno > 0 THEN LET l_stmt = l_stmt CLIPPED," WHERE order_number = ",l_ordno END IF
	LET l_stmt = l_stmt CLIPPED," ORDER BY order_number"
	TRY
		PREPARE pre FROM l_stmt
		DECLARE cur CURSOR FOR pre
	CATCH
		DISPLAY "Failed to prepare/declare statement:",l_stmt
	END TRY

	LET l_row = 1
	DECLARE cur2 CURSOR FOR SELECT 
			stock_code, pack_flag, price, quantity,disc_percent, 
			disc_value,tax_value,tax_code,tax_rate,
			nett_value, gross_value
		 FROM ord_detail WHERE order_number = g_ordHead.order_number

	DECLARE cur3 CURSOR FOR SELECT barcode, description
		 FROM stock WHERE stock_code = ?

	PREPARE packPre FROM "SELECT p.*,s.description FROM pack_items p,stock s WHERE p.pack_code = ? AND s.stock_code = p.stock_code"
	DECLARE packCur CURSOR FOR packPre

	LET l_rptStart = FALSE
	FOREACH cur INTO g_ordHead.*
		IF NOT l_rptStart THEN
			LET l_handler = glGRW_rptStart(l_report)
			IF l_handler IS NULL THEN EXIT PROGRAM END IF
			CALL bm_start()
			CALL glGRW_printMessage(1,%"Printing, please wait...")
			START REPORT rpt TO XML HANDLER l_handler
			LET l_rptStart = TRUE
		END IF

		CALL  g_detailArray.clear()
		FOREACH cur2 INTO
 				 g_detailArray[  g_detailArray.getLength() + 1 ].stock_code,
				 g_detailArray[  g_detailArray.getLength() ].pack_flag,
				 g_detailArray[  g_detailArray.getLength() ].price,
				 g_detailArray[  g_detailArray.getLength() ].quantity,
				 g_detailArray[  g_detailArray.getLength() ].disc_percent,
				 g_detailArray[  g_detailArray.getLength() ].disc_value,
				 g_detailArray[  g_detailArray.getLength() ].tax_value,
				 g_detailArray[  g_detailArray.getLength() ].tax_code,
				 g_detailArray[  g_detailArray.getLength() ].tax_rate,
				 g_detailArray[  g_detailArray.getLength() ].nett_value,
				 g_detailArray[  g_detailArray.getLength() ].gross_value
			LET l_row =  g_detailArray.getLength()

			OPEN cur3 USING  g_detailArray[ l_row ].stock_code
			FETCH cur3 INTO  g_detailArray[ l_row ].barcode, 
											 g_detailArray[ l_row ].description
			CLOSE cur3

			IF  g_detailArray[ l_row ].price IS NULL THEN LET  g_detailArray[ l_row ].price = 0 END IF
			IF  g_detailArray[ l_row ].quantity IS NULL THEN LET  g_detailArray[ l_row ].quantity = 0 END IF
			IF  g_detailArray[ l_row ].disc_percent IS NULL THEN LET  g_detailArray[ l_row ].disc_percent = 0 END IF
			IF  g_detailArray[ l_row ].pack_flag IS NULL THEN LET  g_detailArray[ l_row ].pack_flag = "N" END IF
			--DISPLAY "Detail Line:",l_row," pack_flag:", g_detailArray[l_row].pack_flag
			IF  g_detailArray[l_row].pack_flag = "P" THEN
				LET l_pack_qty =  g_detailArray[ l_row ].quantity
				FOREACH packCur USING  g_detailArray[ l_row ].stock_code
					INTO l_packcode,l_pack.*
					--DISPLAY "Pack item:",l_pack.stock_code
					LET  g_detailArray[  g_detailArray.getLength() + 1 ].stock_code = l_pack.stock_code
					LET  g_detailArray[  g_detailArray.getLength() ].pack_flag = "p" -- exploded
					LET  g_detailArray[  g_detailArray.getLength() ].description = l_pack.description
					LET  g_detailArray[  g_detailArray.getLength() ].quantity = l_pack.qty * l_pack_qty
					LET  g_detailArray[  g_detailArray.getLength() ].price = 0
					LET  g_detailArray[  g_detailArray.getLength() ].disc_percent = 0
					LET  g_detailArray[  g_detailArray.getLength() ].disc_value = 0
					LET  g_detailArray[  g_detailArray.getLength() ].tax_code = l_pack.tax_code
					LET  g_detailArray[  g_detailArray.getLength() ].tax_rate = 0
					LET  g_detailArray[  g_detailArray.getLength() ].tax_value = 0
					LET  g_detailArray[  g_detailArray.getLength() ].nett_value = 0
					LET  g_detailArray[  g_detailArray.getLength() ].gross_value = 0
					OPEN cur3 USING  g_detailArray[ g_detailArray.getLength() ].stock_code
					FETCH cur3 INTO  g_detailArray[ g_detailArray.getLength() ].barcode, 
													 g_detailArray[ g_detailArray.getLength() ].description
					CLOSE cur3
				END FOREACH
			END IF
		END FOREACH
		CALL printInv()
	END FOREACH

	IF l_rptStart THEN
		FINISH REPORT rpt
		CALL glGRW_printMessage(2,"")
		CALL glGRW_rptFinish( l_row )
	ELSE
		CALL glGRW_printMessage(1,%"No Orders to print")
		SLEEP 3
		CALL glGRW_printMessage(2,"")
	END IF
	{IF STATUS != 0 THEN
		CALL gl_showErrors()
	END IF}
	DISPLAY "Finished."
	CALL bm_end()
END MAIN
--------------------------------------------------------------------------------
FUNCTION printInv()
	DEFINE l_row SMALLINT

	DISPLAY "Order:", g_ordHead.order_number
	FOR l_row = 1 TO  g_detailArray.getLength()	
		IF  g_detailArray[l_row].stock_code IS NOT NULL
		AND  g_detailArray[l_row].stock_code != " " THEN
			OUTPUT TO REPORT rpt( m_user.username, g_ordHead.*,  g_detailArray[l_row].* )
		END IF
	END FOR

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION chk_libs(libs,ext)
	DEFINE libs,pth,lib,ext STRING
	DEFINE dirs,libns DYNAMIC ARRAY OF STRING
	DEFINE st base.StringTokenizer
	DEFINE x,y,found SMALLINT

	LET pth = fgl_getEnv("FGLLDPATH")
	DISPLAY "FGLLDPATH:", pth
	DISPLAY "ProgramDir:",base.Application.getProgramDir()
	DISPLAY "PWD:",os.path.pwd()

	LET st = base.StringTokenizer.create(pth,":")
	WHILE st.hasMoreTokens()
		LET dirs[ dirs.getLength() + 1] = st.nextToken()
	END WHILE
	LET st = base.StringTokenizer.create(libs,",")
	WHILE st.hasMoreTokens()
		LET libns[ libns.getLength() + 1] = st.nextToken()||ext
	END WHILE
	FOR x = 1 TO libns.getLength()
		LET found = FALSE
		FOR y = 1 TO dirs.getLength()
			LET lib = dirs[y]||os.path.separator()||libns[x]
			--DISPLAY "Looking for ",lib
			IF os.Path.exists( lib ) THEN
				DISPLAY "Found:",lib
				LET found = TRUE
			END IF
		END FOR
		IF NOT found THEN
			DISPLAY "Not Found:",libns[x]
		END IF
	END FOR

END FUNCTION
--------------------------------------------------------------------------------

#+ The Invoice report
#+
#+ @param rpt_user User id of current user
#+ @param r_ordHead The order header record
#+ @param r_detailLine Array of detail line records.
REPORT rpt( rpt_user, r_ordHead , r_detailLine )
	DEFINE rpt_user STRING
	DEFINE r_ordhead RECORD LIKE ord_head.*
	DEFINE r_detailline t_detailline
  DEFINE print_date, order_date DATE
  DEFINE rpt_timestamp DATETIME HOUR TO SECOND
	DEFINE line_num SMALLINT
	DEFINE tax_0, tax_1, tax_2, tax_3 DECIMAL(10,2)

	ORDER EXTERNAL BY r_ordHead.order_number

  FORMAT
		FIRST PAGE HEADER
			LET print_date = TODAY
			PRINT print_date, rpt_user, m_logo
			DISPLAY "First Page Header"

		BEFORE GROUP OF r_ordHead.order_number
			LET order_date = r_ordHead.order_datetime
			DISPLAY "DEBUG GROUP:",r_ordHead.customer_name
			LET line_num = 0
			LET tax_0 = 0
			LET tax_1 = 0
			LET tax_2 = 0
			LEt tax_3 = 0
			PRINT r_ordhead.*, order_date

		BEFORE GROUP OF r_detailLine.pack_flag
			--DISPLAY "Pack:",r_detailLine.pack_flag

		ON EVERY ROW
			IF r_detailLine.tax_code = "0" THEN
				LET tax_0 = tax_0 + r_detailLine.tax_value
			END IF
			IF r_detailLine.tax_code = "1" THEN
				LET tax_1 = tax_1 + r_detailLine.tax_value
			END IF
			IF r_detailLine.tax_code = "2" THEN
				LET tax_2 = tax_2 + r_detailLine.tax_value
			END IF
			IF r_detailLine.tax_code = "3" THEN
				LET tax_3 = tax_3 + r_detailLine.tax_value
			END IF
			IF r_detailLine.barcode IS NULL THEN
				LET r_detailLine.barcode = r_detailline.stock_code
			END IF
			LET line_num = line_num + 1
			LET rpt_timestamp = CURRENT
			DISPLAY "DEBUG: ON EVERY ROW:",r_detailLine.stock_code," bc:",r_detailLine.barcode
			PRINT r_detailline.*
			PRINT tax_0, tax_1, tax_2, tax_3
			PRINT rpt_timestamp, line_num

END REPORT