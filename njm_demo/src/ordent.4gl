
#+ Order Entry Demo - by N.J.Martin neilm@4js.com
#+
#+ $Id: ordent.4gl 961 2016-06-23 10:32:51Z neilm $
#+
#+ Parameters:
#+ 1 = S / C  - SDI / Child
#+ 2 = User Id
#+ 3 = E - Enquiry only
#+ 4 = Order No to enquire on / R = Random(for benchmark only)

IMPORT util

CONSTANT VER = "$Rev: 961 $"
CONSTANT PRGNAME = "Ordent"
CONSTANT PRGDESC = "Order Entry Demo"
CONSTANT PRGAUTH = "Neil J.Martin"

&define ABOUT 		ON ACTION about \
			CALL gl_about( VER )
&define TIMELOG CALL timeLogIt(PRGNAME,__LINE__)
&include "schema.inc"
&include "ordent.inc"
&include "genero_lib1.inc" -- Contains GL_DBGMSG & g_dbgLev

DEFINE m_dbtyp STRING
DEFINE m_arg1, m_arg2 STRING
MAIN
	DEFINE l_test STRING

	CALL gl_init(ARG_VAL(1),NULL,TRUE)
GL_MODULE_ERROR_HANDLER
	CALL timeLogOn()

--	CALL chkFont()
	CALL gldb_connect(NULL) -- Library function.
	TIMELOG
	LET m_arg1 = ARG_VAL(1)
	IF m_arg1 IS NULL OR m_arg1 = " " THEN LET m_arg1 = "SDI" END IF
	LET m_arg2 = ARG_VAL(2)
	IF m_arg2 IS NULL OR m_arg2 = " " THEN LET m_arg2 = "1" END IF
	LET m_dbtyp = gldb_getDBType()

	IF UPSHIFT(ui.Interface.getFrontEndName()) = "GWC" THEN
		CALL ui.Interface.FrontCall("session","getvar","login",l_test)
		TRY
			LET m_user.user_key = l_test
		CATCH
--ah? char to num error ??
		END TRY
		DISPLAY "From cookie:",l_test
	ELSE
		LET m_user.username = fgl_getEnv("REALUSER")
	END IF
	IF m_user.user_key > 1 THEN
		LET m_user.fullname = getUserName(m_user.user_key)
		DISPLAY "User:",m_user.fullname,":",m_user.def_cust
	END IF
	TIMELOG
	CALL oe_cursors()
	TIMELOG

	OPEN FORM ordent2 FROM "ordent2"
	DISPLAY FORM ordent2

	DISPLAY "Welcome "||m_user.fullname TO welcome
	--CALL setTitle()
	TIMELOG
	IF ARG_VAL(3) = "E" THEN
		CALL enquire()
	ELSE
		MENU
			BEFORE MENU
				TIMELOG

    	ON ACTION qa_dialog_ready
				DISPLAY "QA Play"
      	--CALL ui.Interface.frontcall("qa","playEventList",["<exit>", 5, 1],[m_result])

			ON ACTION new
				CALL new()
			ON ACTION update -- NOT DONE YET!
				CALL enquire()
			ON ACTION enquire
				CALL enquire()
			ON ACTION getcust
				CALL getCust()
			ON ACTION getstock
				CALL getStock("") RETURNING stk.*
			ON ACTION help
				CALL showHelp(1)
			ABOUT
			ON ACTION close
				EXIT MENU
			ON ACTION exit
				EXIT MENU
		END MENU
	END IF
	DISPLAY "Program Finished"
	CALL exit_Program()
END MAIN
--------------------------------------------------------------------------------
#+ Create a new order.
FUNCTION new()
	DEFINE l_row SMALLINT
	DEFINE l_prevQty LIKE ord_detail.quantity

	CALL initVariables()
	DISPLAY FORM ordent
	CLEAR FORM
	MESSAGE "Enter Header details."
	INPUT BY NAME g_ordHead.customer_code, g_ordHead.order_ref, g_ordhead.req_del_date
		 ATTRIBUTES(UNBUFFERED, WITHOUT DEFAULTS) HELP 2
		BEFORE INPUT
			IF m_user.def_cust IS NOT NULL AND m_user.def_cust != 0 THEN
				CALL DIALOG.setFieldActive("customer.customer_code",FALSE)
			END IF
		AFTER FIELD customer_code
			SELECT * INTO g_cust.* FROM customer WHERE customer_code = g_ordHead.customer_code
			IF STATUS = NOTFOUND THEN
				CALL fgl_winMessage("Error","Customer you seek cannot be located, but countless more exist.\nCode:"||g_ordHead.customer_code,"exclamation")
				NEXT FIELD customer_code
			END IF
			CALL dispHead()
		ON ACTION getcust
			CALL getCust()
			CALL dispHead()
		ABOUT
	END INPUT
	IF int_flag THEN
		MESSAGE "Order Cancelled."
		LET int_flag = FALSE
		RETURN
	END IF
	IF g_ordhead.req_del_date IS NULL THEN LET g_ordhead.req_del_date = (g_ordhead.order_date + 10) END IF
	BEGIN WORK -- Start the transaction.
	LET g_ordHead.order_datetime = CURRENT
--	IF m_dbtyp = "sqt" THEN LET g_ordHead.order_number = NULL END IF
	INSERT INTO ord_head VALUES g_ordHead.* 
	LET g_ordHead.order_number = SQLCA.SQLERRD[2] -- Fetch SERIAL order num
	DISPLAY BY NAME g_ordHead.*

	MESSAGE "Enter Details Lines."
	INPUT ARRAY g_detailArray FROM details.* ATTRIBUTE(UNBUFFERED, WITHOUT DEFAULTS) HELP 3
		ON ACTION getstock INFIELD stock_code
			LET g_detailArray[ arr_curr() ].stock_code = fgl_dialog_getBuffer()
			CALL getStock( g_detailArray[ arr_curr() ].stock_code ) RETURNING stk.*
			IF stk.stock_code IS NOT NULL THEN
				LET g_detailArray[ l_row ].stock_code = stk.stock_code
				IF NOT oe_getStockRec(DIALOG.getCurrentRow("details"),TRUE) THEN
					NEXT FIELD stock_code
				END IF
				IF stk.stock_code IS NOT NULL THEN
					NEXT FIELD quantity
				END IF
			END IF

		BEFORE INSERT
			LET g_detailArray[ l_row ].accepted = FALSE

		BEFORE FIELD stock_code
			IF g_detailArray[ l_row ].accepted THEN
				ERROR "Can't change product code on an accept line!"
				NEXT FIELD quantity
			END IF

		AFTER FIELD stock_code
			IF g_detailArray[ l_row ].stock_code IS NOT NULL THEN
				IF NOT oe_getStockRec(l_row,TRUE) THEN
					NEXT FIELD stock_code
				END IF
				IF stk.stock_code IS NOT NULL THEN
					NEXT FIELD quantity
				END IF
			END IF
			MESSAGE ""

		BEFORE FIELD quantity -- Store previous qty
			SELECT free_stock INTO g_detailArray[ l_row ].stock 
				FROM stock -- refresh stock value.
			 WHERE stock_code = g_detailArray[ l_row ].stock_code
			LET l_prevQty = g_detailArray[ l_row ].quantity

		AFTER FIELD quantity
			CALL oe_calcLineTot( l_row )

		AFTER FIELD disc_percent
			CALL oe_calcLineTot( l_row )

		AFTER FIELD tax_code
			CALL oe_calcLineTot( l_row )

		BEFORE FIELD accepted
			IF g_detailArray[ l_row ].accepted THEN
				NEXT FIELD quantity
			END IF

		BEFORE ROW
			LET l_row = DIALOG.getCurrentRow("details")
			MESSAGE "BR Item:", l_row

		AFTER ROW
			MESSAGE "AR Item:", l_row
			IF g_detailArray[ l_row ].stock_code IS NOT NULL THEN
				IF ( g_detailArray[ l_row ].quantity IS NULL
					OR g_detailArray[ l_row ].quantity < 1) THEN
					ERROR "Quantity must be greater than 0!"
					NEXT FIELD quantity
				END IF
				SELECT free_stock INTO stk.free_stock
					FROM stock -- refresh stock value.
				 WHERE stock_code = g_detailArray[ l_row ].stock_code
				IF g_detailArray[ l_row ].quantity > stk.free_stock THEN
					ERROR "Not enough stock!"
					NEXT FIELD quantity
				END IF
				CALL oe_explodePack(l_row)
				DISPLAY BY NAME 
						g_ordHead.items,
						g_ordHead.total_qty, 
						g_ordHead.total_disc,
						g_ordHead.total_tax,
						g_ordHead.total_gross,
						g_ordHead.total_nett
				IF g_detailArray[ l_row ].accepted AND l_prevQty IS NOT NULL
				AND l_prevQty != 0 THEN -- Undo previous stock adjustment.
					IF NOT updateStockLevel(l_row,  g_detailArray[ l_row ].stock_code, 0 - l_prevQty ) THEN -- replace stock
						NEXT FIELD quantity
					END IF
				END IF
				IF NOT updateStockLevel(l_row,  g_detailArray[ l_row ].stock_code, g_detailArray[ l_row ].quantity ) THEN -- remove stock
					NEXT FIELD quantity
				END IF
				LET g_detailArray[ l_row ].accepted = TRUE
				MESSAGE "Accepted"
			END IF

		BEFORE DELETE
			IF fgl_winQuestion("Confirm","Are you sure you want to remove this line?","No","Yes|No","question",0) = "Yes" THEN
				IF NOT updateStockLevel(l_row, g_detailArray[ l_row ].stock_code, 0 - g_detailArray[ l_row ].quantity ) THEN -- replace stock
					MESSAGE "Delete cancelled."
					CANCEL DELETE
				ELSE
					MESSAGE "Line deleted."
				END IF
			ELSE
				MESSAGE "Delete cancelled."
				CANCEL DELETE
			END IF

		AFTER DELETE
			CALL oe_calcOrderTot()
			DISPLAY BY NAME 
					g_ordHead.items,
					g_ordHead.total_qty, 
					g_ordHead.total_disc,
					g_ordHead.total_tax,
					g_ordHead.total_gross,
					g_ordHead.total_nett

		AFTER INPUT
			IF NOT int_flag THEN
				IF fgl_winQuestion("Accept","Accept this order?","Yes","Yes|No","question",0) = "No" THEN
					CONTINUE INPUT
				END IF
			ELSE
				IF fgl_winQuestion("Cancel","Cancel this order?","No","Yes|No","question",0) = "No" THEN
					LET int_flag = FALSE
					CONTINUE INPUT
				END IF
			END IF
		ABOUT
	END INPUT
	IF int_flag THEN
		ROLLBACK WORK -- Rollback and end transaction.
		LET int_flag = FALSE
		ERROR "Order Cancelled."
		RETURN
	END IF

	FOR l_row = 1 TO g_detailArray.getLength()
		IF g_detailArray[ l_row ].accepted THEN
			INSERT INTO ord_detail VALUES( 
				g_ordHead.order_number,
				l_row,
				g_detailArray[ l_row ].stock_code,
				g_detailArray[ l_row ].pack_flag,
				g_detailArray[ l_row ].price,
				g_detailArray[ l_row ].quantity,
				g_detailArray[ l_row ].disc_percent,
				g_detailArray[ l_row ].disc_value,
				g_detailArray[ l_row ].tax_code,
				g_detailArray[ l_row ].tax_rate,
				g_detailArray[ l_row ].tax_value,
				g_detailArray[ l_row ].nett_value,
				g_detailArray[ l_row ].gross_value  )
		END IF
	END FOR
	UPDATE ord_head SET ord_head.* = g_ordHead.* WHERE order_number = g_ordHead.order_number
	COMMIT WORK -- Commit and end transaction.

	MENU "Order Details" 
		ATTRIBUTES(STYLE="dialog",
						COMMENT="Order "||g_ordHead.order_number||" Created.\nPrint Invoice?", 
						IMAGE="question")
		ON ACTION continue
			EXIT MENU
		ON ACTION print
			CALL printInv("ordent")
	END MENU
END FUNCTION
--------------------------------------------------------------------------------
#+ Update the stock levels
#+
#+ @param l_row Row number without detail line array
#+ @param l_pcode Stock Product Code
#+ @param l_qty Quantity to adjust stock by
FUNCTION updateStockLevel(l_row, l_pcode, l_qty)
	DEFINE l_row SMALLINT
	DEFINE l_pcode LIKE stock.stock_code
	DEFINE l_qty INTEGER

	DISPLAY "Update Stock:",l_pcode,":",l_qty
	TRY
		UPDATE stock SET ( allocated_stock, free_stock ) =
									( allocated_stock + l_qty, free_stock - l_qty )
			WHERE stock_code = l_pcode
	CATCH
		DISPLAY "Status:",STATUS,":",SQLERRMESSAGE
		CALL fgl_winMessage("Error","Unable to allocate stock!\nMaybe try again in a few minutes\nOr try a smaller quantity.","exclamation")
		RETURN FALSE
	END TRY
	RETURN TRUE

END FUNCTION
--------------------------------------------------------------------------------
#+ Set and Display the header detail.
FUNCTION dispHead()
	IF g_ordHead.del_address1 IS NULL OR g_ordHead.del_address1 = " " THEN
		CALL oe_setHead( g_cust.customer_code,g_cust.del_addr,g_cust.inv_addr )
	END IF
	DISPLAY BY NAME g_ordHead.*
	DISPLAY BY NAME g_cust.customer_name
END FUNCTION
--------------------------------------------------------------------------------
#+ Clear the main order records and array.
FUNCTION initVariables()

	INITIALIZE g_ordHead.* TO NULL
	LET g_ordHead.order_number = 0
	LET g_ordHead.order_date = TODAY
	LET g_ordHead.username = fgl_getEnv("LOGNAME")
	IF g_ordHead.username IS NULL THEN LET g_ordHead.username = fgl_getEnv("USERNAME") END IF
	CALL g_detailArray.clear()
	CALL detailArray_tree.clear()

	IF LENGTH(m_user.username) > 1 THEN
		LET g_ordHead.customer_code = m_user.def_cust
		SELECT * INTO g_cust.* FROM customer WHERE customer_code = g_ordHead.customer_code
		CALL dispHead()
	END IF
END FUNCTION
--------------------------------------------------------------------------------
#+ Enquire on a Order
FUNCTION enquire()
	DEFINE l_packcode CHAR(8)
	DEFINE l_pack t_packItem
	DEFINE l_pack_id SMALLINT
	DEFINE l_pack_qty, l_ords INTEGER
	DEFINE f ui.Form
	DEFINE l_arg4 STRING
	DEFINE benchmark BOOLEAN
	TIMELOG
	DECLARE ordCur CURSOR FOR SELECT stock_code,pack_flag, price, quantity, disc_percent, 
				disc_value, tax_code, tax_rate, tax_value, nett_value, gross_value
			FROM ord_detail WHERE order_number = g_ordHead.order_number
				ORDER BY line_number

	DECLARE packCur CURSOR FROM 
		"SELECT p.*,s.description FROM pack_items p,stock s WHERE p.pack_code = ? AND s.stock_code = p.stock_code"

	LET benchmark = FALSE
	WHILE TRUE
		DISPLAY FORM ordent2
		CLEAR FORM
		CALL initVariables()
		LET int_flag = FALSE
TIMELOG
		LET l_arg4 = ARG_VAL(4)
		IF ARG_VAL(3) = "E" AND l_arg4.getLength() > 0 THEN
			IF l_arg4 = "R" THEN -- benchmark only
				SELECT COUNT(*) INTO l_ords FROM ord_head
				LET g_ordHead.order_number = util.math.rand( l_ords )
				LET benchmark = TRUE
			ELSE
				LET g_ordHead.order_number = l_arg4
			END IF
		ELSE
			INPUT BY NAME g_ordHead.order_number ATTRIBUTE(UNBUFFERED)
				ON ACTION getorder
					CALL getOrder() RETURNING g_ordHead.order_number
					IF g_ordHead.order_number IS NOT NULL THEN EXIT INPUT END IF
				ABOUT
			END INPUT
		END IF
		IF int_flag THEN 
			LET int_flag = FALSE
			RETURN 
		END IF
		SELECT * INTO g_ordHead.* FROM ord_head WHERE order_number = g_ordHead.order_number
		IF STATUS = NOTFOUND THEN
			CALL fgl_winMessage("Error","Order not found.","exclamation")
			CONTINUE WHILE
		END IF

		SELECT * INTO g_cust.* FROM customer WHERE customer_code = g_ordHead.customer_code
		IF STATUS = NOTFOUND THEN
			CALL fgl_winMessage("Error","customer not found\nCode="||g_ordHead.customer_code,"exclamation")
		END IF
		CALL dispHead()
TIMELOG
		FOREACH ordCur INTO
				detailArray_tree[ detailArray_tree.getLength() + 1 ].stock_code,
				detailArray_tree[ detailArray_tree.getLength() ].pack_flag,
				detailArray_tree[ detailArray_tree.getLength() ].price,
				detailArray_tree[ detailArray_tree.getLength() ].quantity,
				detailArray_tree[ detailArray_tree.getLength() ].disc_percent,
				detailArray_tree[ detailArray_tree.getLength() ].disc_value,
				detailArray_tree[ detailArray_tree.getLength() ].tax_code,
				detailArray_tree[ detailArray_tree.getLength() ].tax_rate,
				detailArray_tree[ detailArray_tree.getLength() ].tax_value,
				detailArray_tree[ detailArray_tree.getLength() ].nett_value,
				detailArray_tree[ detailArray_tree.getLength() ].gross_value
			LET detailArray_tree[ detailArray_tree.getLength() ].id = detailArray_tree.getLength()
			LET detailArray_tree[ detailArray_tree.getLength() ].parentid = 0

			SELECT description
				INTO detailArray_tree[ detailArray_tree.getLength() ].description
				FROM stock WHERE stock_code = detailArray_tree[ detailArray_tree.getLength() ].stock_code

			IF detailArray_tree[ detailArray_tree.getLength() ].pack_flag = "P" THEN
				LET l_pack_id = detailArray_tree.getLength()
				LET l_pack_qty = detailArray_tree[ detailArray_tree.getLength() ].quantity
				FOREACH packCur USING detailArray_tree[ detailArray_tree.getLength() ].stock_code
					INTO l_packcode,l_pack.*
					LET detailArray_tree[ detailArray_tree.getLength() + 1 ].stock_code = l_pack.stock_code
					LET detailArray_tree[ detailArray_tree.getLength() ].description = l_pack.description
					LET detailArray_tree[ detailArray_tree.getLength() ].quantity = l_pack.qty * l_pack_qty
					LET detailArray_tree[ detailArray_tree.getLength() ].price = 0
					LET detailArray_tree[ detailArray_tree.getLength() ].disc_percent = 0
					LET detailArray_tree[ detailArray_tree.getLength() ].disc_value = 0
					LET detailArray_tree[ detailArray_tree.getLength() ].tax_code = l_pack.tax_code
					LET detailArray_tree[ detailArray_tree.getLength() ].tax_rate = 0
					LET detailArray_tree[ detailArray_tree.getLength() ].tax_value = 0
					LET detailArray_tree[ detailArray_tree.getLength() ].nett_value = 0
					LET detailArray_tree[ detailArray_tree.getLength() ].gross_value = 0

					LET detailArray_tree[ detailArray_tree.getLength() ].id = detailArray_tree.getLength()
					LET detailArray_tree[ detailArray_tree.getLength() ].parentid = l_pack_id
				END FOREACH
				--CALL detailArray_tree.deleteElement( detailArray_tree.getLength()  ) -- remove empty read.
			END IF

		END FOREACH
		CALL detailArray_tree.deleteElement( detailArray_tree.getLength()  ) -- remove empty read.
TIMELOG
		MESSAGE detailArray_tree.getLength()," Details Lines"
		DISPLAY ARRAY detailArray_tree TO details.*
			BEFORE DISPLAY
				LET f = DIALOG.getForm()
			ON IDLE 2
				IF benchmark THEN
					EXIT DISPLAY
				END IF
{
    	ON ACTION qa_dialog_ready
				DISPLAY "QA Play"
      	CALL ui.Interface.frontcall("qa","playEventList",["<F12>", 5, 1],[m_result])
}
			ON ACTION accept EXIT DISPLAY
			ON ACTION enquire EXIT DISPLAY
			ON ACTION update CALL update()
			ON ACTION print CALL printInv("ordent")
			ON ACTION picklist CALL printInv("picklist")
			ON ACTION hideaddr
				CALL f.setElementHidden("addr",TRUE)
				CALL f.setElementHidden("addr2",FALSE)
			ON ACTION showaddr
				CALL f.setElementHidden("addr",FALSE)
				CALL f.setElementHidden("addr2",TRUE)
			ON ACTION close EXIT DISPLAY
			--ON KEY (F12) DISPLAY "F12" LET int_flag = TRUE EXIT DISPLAY
		END DISPLAY
TIMELOG
		IF benchmark OR int_flag THEN EXIT WHILE END IF
	END WHILE

END FUNCTION
--------------------------------------------------------------------------------

--TODO: Write these :)
--------------------------------------------------------------------------------
#+ Update an Order
FUNCTION update()
END FUNCTION
--------------------------------------------------------------------------------
#+ Print an Invoice
#+
FUNCTION printInv(l_what)
	DEFINE l_what STRING
	DEFINE l_rptTo STRING

	IF fgl_getEnv("BENCHMARK") = "true" THEN
		DISPLAY "Printing Invoice:",g_ordHead.order_number
		RUN "fglrun printInvoices.42r "||m_arg1||" "||m_arg2||" "||g_ordHead.order_number||" "||l_what||".4rp PDF save 0 "||fgl_getPID()||".pdf"
		RETURN
	END IF

	IF UPSHIFT(ui.interface.getFrontEndName()) = "GDC" THEN
		LET l_rptTo = "SVG"
	ELSE
		LET l_rptTo = "PDF"
	END IF

	DISPLAY "Printing Invoice:",g_ordHead.order_number
	RUN "fglrun printInvoices.42r "||m_arg1||" "||m_arg2||" "||g_ordHead.order_number||" "||l_what||".4rp "||l_rptTo||" preview 1"

END FUNCTION
--------------------------------------------------------------------------------
#+ Order Browse List
#+
FUNCTION getOrder()
	DEFINE arr DYNAMIC ARRAY OF RECORD
		order_number LIKE ord_head.order_number,
		order_date LIKE ord_head.order_date,
		customer_name LIKE customer.customer_name,
		items INTEGER,
		order_qty INTEGER,
		order_value DECIMAL(12,2)
	END RECORD
	DEFINE l_oh RECORD LIKE ord_head.*

-- Declares
	DECLARE cstnamcur CURSOR FOR SELECT customer_name FROM customer 
		WHERE customer_code = l_oh.customer_code
	DECLARE ordenqcur CURSOR FOR SELECT * FROM ord_head
		ORDER BY order_number

	FOREACH ordenqcur INTO l_oh.*
		LET arr[ arr.getLength() + 1].order_number = l_oh.order_number
		LET arr[ arr.getLength() ].order_date = l_oh.order_date
		LET arr[ arr.getLength() ].items = l_oh.items
		LET arr[ arr.getLength() ].order_qty = l_oh.total_qty
		LET arr[ arr.getLength() ].order_value = l_oh.total_nett
		OPEN cstnamcur
		FETCH cstnamcur INTO arr[ arr.getLength() ].customer_name
	END FOREACH
TIMELOG
	OPEN WINDOW getorder WITH FORM "getorder"
	LET int_flag = FALSE
	DISPLAY ARRAY arr TO arr.*
		ABOUT
	END DISPLAY
	CLOSE WINDOW getorder
TIMELOG
	IF int_flag THEN
		LET int_flag = FALSE
		RETURN NULL
	END IF
	RETURN arr[ arr_curr() ].order_number

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION chkFont()
	DEFINE scr_x SMALLINT
	DEFINE tmp, fontsize STRING
	DEFINE dn1,dn2 om.domNode
	DEFINE nl om.nodeList
	CALL ui.Interface.frontCall("standard","feinfo","screenresolution",tmp)
	DISPLAY "FE:",tmp	
	LET scr_x = tmp.getIndexOf("x",1)
	LET scr_x  = tmp.subString(1,scr_x-1)
	CASE scr_x
		WHEN 1600 LET fontSize = "14pt"
		WHEN 1280 LET fontSize = "8pt"
		OTHERWISE LET fontSize = "10pt"
	END CASE
	DISPLAY "FontSize:",fontSize
	LET dn1 = ui.Interface.getRootNode()
	LET nl = dn1.selectByPath("//Style[@name='Window']")
	IF nl.getLength() > 0 THEN
		LET dn1 = nl.item(1)
		LET dn2 = dn1.createChild("StyleAttribute")
		CALL dn2.setAttribute("name","fontSize")
		CALL dn2.setAttribute("value",fontSize)
	ELSE
		DISPLAY "Failed to find style 'Window'"
	END IF
END FUNCTION
--------------------------------------------------------------------------------
