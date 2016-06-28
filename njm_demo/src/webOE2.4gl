
#+ Web Order Entry Demo - by N.J.Martin neilm@4js.com
#+
#+ $Id: webOE.4gl 960 2016-06-13 14:39:50Z neilm $

IMPORT FGL lib_weboe

CONSTANT PRGNAME = "webOE2"
CONSTANT PRGDESC = "Web Ordering Demo"
CONSTANT PRGAUTH = "Neil J.Martin"

&define ABOUT 		ON ACTION about \
			CALL gl_about( VER )

&include "schema.inc"
&include "ordent.inc"

&ifdef CLOUD
	&include "../lib/varServices.inc"
	&define m_VARCODE "fjsuk"
	&define m_VARPASS "12fjsuk"
	DEFINE m_soapStatus INTEGER
&endif

DEFINE m_dbtyp STRING
DEFINE m_arg1,m_arg2 STRING
DEFINE m_stock_cats DYNAMIC ARRAY OF RECORD
		id LIKE stock_cat.catid,
		desc LIKE stock_cat.cat_name
	END RECORD
DEFINE m_items DYNAMIC ARRAY OF RECORD
		stock_code1 STRING,
		img1 STRING,
		desc1 STRING,
		qty1 INTEGER,
		stock_code2 STRING,
		img2 STRING,
		desc2 STRING,
		qty2 INTEGER,
		stock_code3 STRING,
		img3 STRING,
		desc3 STRING,
		qty3 INTEGER,
		stock_code4 STRING,
		img4 STRING,
		desc4 STRING,
		qty4 INTEGER
	END RECORD

DEFINE m_pay RECORD LIKE ord_payment.*
MAIN
	DEFINE l_test STRING
	DEFINE l_em LIKE customer.email

	CALL gl_setInfo(NULL, "njm_demo", "njm_demo", PRGNAME, PRGDESC, PRGAUTH)
	CALL gl_init(ARG_VAL(1),"weboe",TRUE)

	CALL gldb_connect(NULL)

	LET m_arg1 = ARG_VAL(1)
	IF m_arg1 IS NULL OR m_arg1 = " " THEN LET m_arg1 = "SDI" END IF
	LET m_arg2 = ARG_VAL(2)
	DISPLAY "webOE2 - arg2:",m_arg2
	IF m_arg2 IS NULL OR m_arg2 = " " THEN LET m_arg2 = "1" END IF
	LET m_dbtyp = gldb_getDBType()

	IF ui.Interface.getFrontEndName() = "GWC" THEN
		CALL ui.Interface.FrontCall("session","getvar","login",l_test)
		LET m_user.user_key = l_test
		DISPLAY "From cookie:",l_test
	ELSE
		LET m_user.username = fgl_getEnv("REALUSER")
	END IF
	IF m_user.user_key > 1 THEN
		LET m_user.fullname = getUserName(m_user.user_key)
		DISPLAY "User:",m_user.fullname,":",m_user.def_cust
	END IF

	OPEN FORM weboe FROM "webOE2"
	DISPLAY FORM weboe

	CALL initAll()

	IF m_arg2.getLength() > 0 THEN
		LET l_em = m_arg2.trim()
		DISPLAY "selecting cust:",l_em
		SELECT * INTO g_cust.* FROM customer WHERE email = l_em
		IF STATUS = NOTFOUND THEN
			LET g_custcode = "Guest"
			LET g_custname = "Guest"
		ELSE
			LET g_custcode = g_cust.customer_code
			LET g_custname = g_cust.customer_name
			CALL oe_setHead( g_cust.customer_code,g_cust.del_addr,g_cust.inv_addr )
		END IF
	END IF

	DISPLAY "customer:",g_custname
	DISPLAY g_custname TO custname

	DECLARE stkcur CURSOR FROM "SELECT * FROM stock WHERE stock_cat = ?"

	DECLARE stkcur2 CURSOR FROM "SELECT * FROM stock WHERE stock_code = ?"

	DECLARE sc_cur CURSOR FOR SELECT UNIQUE stock_cat.* FROM stock_cat, stock 
		WHERE stock.stock_cat = stock_cat.catid AND stock_cat.catid != "ARMS"
	FOREACH sc_cur INTO m_stock_cats[ m_stock_cats.getLength() + 1 ].*
	END FOREACH
	CALL m_stock_cats.deleteElement( m_stock_cats.getLength() )

	LET m_pay.del_amount = 0
	DIALOG ATTRIBUTE(UNBUFFERED)
		DISPLAY ARRAY m_stock_cats TO stkcats.*
			BEFORE ROW
				CALL getItems( m_stock_cats[ arr_curr() ].id )
		END DISPLAY
		INPUT ARRAY m_items FROM items.* 
			ATTRIBUTES(WITHOUT DEFAULTS, DELETE ROW=FALSE, INSERT ROW=FALSE, APPEND ROW=FALSE)

			ON CHANGE qty1
				CALL detLine(m_items[DIALOG.getCurrentRow("items")].stock_code1,m_items[DIALOG.getCurrentRow("items")].qty1)
			ON CHANGE qty2
				CALL detLine(m_items[DIALOG.getCurrentRow("items")].stock_code2,m_items[DIALOG.getCurrentRow("items")].qty2)
			ON CHANGE qty3
				CALL detLine(m_items[DIALOG.getCurrentRow("items")].stock_code3,m_items[DIALOG.getCurrentRow("items")].qty3)
			ON CHANGE qty4
				CALL detLine(m_items[DIALOG.getCurrentRow("items")].stock_code4,m_items[DIALOG.getCurrentRow("items")].qty4)

			ON ACTION add1
					CALL detLine(m_items[DIALOG.getCurrentRow("items")].stock_code1,m_items[DIALOG.getCurrentRow("items")].qty1+1)
			ON ACTION add2 
					CALL detLine(m_items[DIALOG.getCurrentRow("items")].stock_code2,m_items[DIALOG.getCurrentRow("items")].qty2+1)
			ON ACTION add3
					CALL detLine(m_items[DIALOG.getCurrentRow("items")].stock_code3,m_items[DIALOG.getCurrentRow("items")].qty3+1)
			ON ACTION add4
					CALL detLine(m_items[DIALOG.getCurrentRow("items")].stock_code4,m_items[DIALOG.getCurrentRow("items")].qty4+1)

			ON ACTION detlnk1 CALL detLnk( m_items[DIALOG.getCurrentRow("items")].stock_code1,
																		 m_items[DIALOG.getCurrentRow("items")].desc1,
                                     m_items[DIALOG.getCurrentRow("items")].img1,
                                     m_items[DIALOG.getCurrentRow("items")].qty1 )
												CALL recalcOrder()
			ON ACTION detlnk2 CALL detLnk( m_items[DIALOG.getCurrentRow("items")].stock_code2,
																		 m_items[DIALOG.getCurrentRow("items")].desc2,
                                     m_items[DIALOG.getCurrentRow("items")].img2,
                                     m_items[DIALOG.getCurrentRow("items")].qty2 )
												CALL recalcOrder()
			ON ACTION detlnk3 CALL detLnk( m_items[DIALOG.getCurrentRow("items")].stock_code3,
																		 m_items[DIALOG.getCurrentRow("items")].desc3,
                                     m_items[DIALOG.getCurrentRow("items")].img3,
                                     m_items[DIALOG.getCurrentRow("items")].qty3 )
												CALL recalcOrder()
			ON ACTION detlnk4 CALL detLnk( m_items[DIALOG.getCurrentRow("items")].stock_code4,
																		 m_items[DIALOG.getCurrentRow("items")].desc4,
                                     m_items[DIALOG.getCurrentRow("items")].img4,
                                     m_items[DIALOG.getCurrentRow("items")].qty4 )
												CALL recalcOrder()
		END INPUT
		BEFORE DIALOG
			CALL DIALOG.setActionActive("viewb", FALSE)
			CALL DIALOG.setActionActive("gotoco", FALSE)

		ON ACTION signin 
			CALL lib_weboe.signin()

		ON ACTION viewb CALL lib_weboe.viewb()
		ON ACTION gotoco CALL gotoco()
		ON ACTION close EXIT DIALOG
		ON ACTION cancel EXIT DIALOG
	END DIALOG

END MAIN
--------------------------------------------------------------------------------
FUNCTION getItems( sc )
	DEFINE sc LiKE stock_cat.catid
	DEFINE l_stk RECORD LIKE stock.*
	DEFINE rec SMALLINT
	DEFINE img STRING

	CALL m_items.clear()
	LET rec = 1
	FOREACH stkcur USING sc INTO l_stk.*
		LET img = "products/"||(l_stk.img_url CLIPPED)
		CASE rec
			WHEN 1
				LET m_items[ m_items.getLength() + 1 ].stock_code1 = l_stk.stock_code
				LET m_items[ m_items.getLength() ].img1 = img.trim()
				LET m_items[ m_items.getLength() ].desc1 = mkDesc( l_stk.*)
				LET m_items[ m_items.getLength() ].qty1 = 0
			WHEN 2
				LET m_items[ m_items.getLength() ].stock_code2 = l_stk.stock_code
				LET m_items[ m_items.getLength() ].img2 = img.trim()
				LET m_items[ m_items.getLength() ].desc2 = mkDesc( l_stk.*)
				LET m_items[ m_items.getLength() ].qty2 = 0
			WHEN 3
				LET m_items[ m_items.getLength() ].stock_code3 = l_stk.stock_code
				LET m_items[ m_items.getLength() ].img3 = img.trim()
				LET m_items[ m_items.getLength() ].desc3 = mkDesc( l_stk.*)
				LET m_items[ m_items.getLength() ].qty3 = 0
			WHEN 4
				LET m_items[ m_items.getLength() ].stock_code4 = l_stk.stock_code
				LET m_items[ m_items.getLength() ].img4 = img.trim()
				LET m_items[ m_items.getLength() ].desc4 = mkDesc( l_stk.*)
				LET m_items[ m_items.getLength() ].qty4 = 0
				LET rec = 0
		END CASE
		LET rec = rec + 1
	END FOREACH
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION detLine(l_sc,l_qty)
	DEFINE l_sc LIKE stock.stock_code
	DEFINE l_qty, l_row INTEGER
	DEFINE l_stk RECORD LIKE stock.*

	FOR l_row = 1 TO g_detailArray.getLength()
		IF l_sc = g_detailArray[l_row].stock_code THEN
			EXIT FOR	
		END IF
	END FOR
	IF l_row = 0 THEN LET l_row = 1 END IF
	IF l_qty = 0 THEN
		CALL g_detailArray.deleteElement(l_row)
		RETURN
	END IF
	OPEN stkcur2 USING l_sc
	FETCH stkcur2 INTO l_stk.*
	LET g_detailArray[l_row].quantity = l_qty
	LET g_detailArray[l_row].stock_code = l_sc
	LET g_detailArray[l_row].description = l_stk.description
	LET g_detailArray[l_row].price = l_stk.price
	CALL recalcOrder()
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION recalcOrder()
	DEFINE x,y SMALLINT
	DEFINE l_d ui.Dialog

	CALL oe_calcOrderTot()
	IF m_pay.del_amount IS NULL THEN DISPLAY "post null" LET m_pay.del_amount = 0 END IF
	DISPLAY BY NAME g_ordHead.total_qty,
			g_ordHead.total_gross,
			g_ordHead.total_disc,
			g_ordHead.total_tax,
			m_pay.del_amount,
			g_ordHead.total_nett

	FOR x = 1 TO m_items.getLength()
		LET m_items[x].qty1 = 0
		LET m_items[x].qty2 = 0
		LET m_items[x].qty3 = 0
		LET m_items[x].qty4 = 0
		FOR y = 1 TO g_detailArray.getLength()
			IF m_items[x].stock_code1 = g_detailArray[y].stock_code THEN
				LET m_items[x].qty1 = g_detailArray[y].quantity
			END IF
			IF m_items[x].stock_code2 = g_detailArray[y].stock_code THEN
				LET m_items[x].qty2 = g_detailArray[y].quantity
			END IF
			IF m_items[x].stock_code3 = g_detailArray[y].stock_code THEN
				LET m_items[x].qty3 = g_detailArray[y].quantity
			END IF
			IF m_items[x].stock_code4 = g_detailArray[y].stock_code THEN
				LET m_items[x].qty4 = g_detailArray[y].quantity
			END IF
		END FOR
	END FOR

	LET l_d = ui.Dialog.getCurrent()
	IF l_d IS NOT NULL THEN
		TRY -- actions maybe not be in current dialog
			IF g_ordHead.total_qty > 0 THEN
				CALL l_d.setActionActive("viewb", TRUE)
				CALL l_d.setActionActive("gotoco", TRUE)
			ELSE
				CALL l_d.setActionActive("viewb", FALSE)
				CALL l_d.setActionActive("gotoco", FALSE)
			END IF
		CATCH
		END TRY
	END IF

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION gotoco()
	DEFINE f ui.Form
	DEFINe l_row SMALLINT
	DEFINE del_amt LIKE ord_payment.del_amount

	IF g_custcode = "Guest" THEN
		CALL lib_weboe.signin()
		IF g_custcode = "Guest" THEN RETURN END IF
	END IF

-- Add code here to place actual order.
	OPEN WINDOW basket WITH FORM "webOE_b"
	DISPLAY g_custname TO custname
	LET int_flag = FALSE
	INITIALIZE m_pay.* TO NULL
	LET m_pay.del_type = "0"
	LET m_pay.del_amount = POST_0
	LET m_pay.payment_type = "C"
	LET m_pay.card_type = "V"
	LET g_ordHead.customer_code = g_cust.customer_code
	LET g_ordHead.customer_name = g_cust.customer_name
	DIALOG ATTRIBUTE(UNBUFFERED)
		INPUT ARRAY g_detailArray FROM dets.* ATTRIBUTE(WITHOUT DEFAULTS,
					DELETE ROW=FALSE,INSERT ROW=FALSE,APPEND ROW=FALSE)
			ON ACTION delete
				CALL g_detailArray.deleteElement( arr_curr() )
				CALL recalcOrder()

			AFTER FIELD qty
				CALL recalcOrder()

			ON ACTION next
				CALL f.setElementHidden("b",TRUE)
				CALL f.setElementHidden("d",FALSE)
				CALL DIALOG.nextField("del_address1")
		END INPUT
		INPUT BY NAME g_ordHead.customer_code, g_ordHead.customer_name,
					g_ordHead.del_address1, g_ordHead.del_address2, g_ordHead.del_address3, g_ordHead.del_address4, g_ordHead.del_address5, g_ordHead.del_postcode,
					g_ordHead.inv_address1, g_ordHead.inv_address2, g_ordHead.inv_address3, g_ordHead.inv_address4, g_ordHead.inv_address5, g_ordHead.inv_postcode,
					m_pay.del_type, del_amt
				ATTRIBUTE(WITHOUT DEFAULTS)
			ON CHANGE del_type
				CASE m_pay.del_type
					WHEN "0" LET m_pay.del_amount = POST_0
					WHEN "1" LET m_pay.del_amount = POST_1
					WHEN "2" LET m_pay.del_amount = POST_2
					WHEN "3" LET m_pay.del_amount = POST_3
				END CASE
				LET del_amt = m_pay.del_amount
				CALL recalcOrder()

			ON ACTION next
				CALL f.setElementHidden("p",FALSE)
				CALL DIALOG.nextField("payment_type")
				CALL f.setElementText("next","Confirm")
				CALL f.setElementImage("next","smiley")
		END INPUT
		INPUT BY NAME g_ordHead.order_ref,
									m_pay.payment_type, 
									m_pay.card_type, m_pay.card_no, 
									m_pay.expires_m, m_pay.expires_y, 
									m_pay.issue_no
				ATTRIBUTE(WITHOUT DEFAULTS)
			ON ACTION next
				EXIT DIALOG
		END INPUT

		BEFORE DIALOG
			LET f = DIALOG.getForm()
			CALL recalcOrder()

		ON ACTION cancel
			LET int_flag = TRUE	
			EXIT DIALOG
	END DIALOG
	CLOSE WINDOW basket
	IF int_flag THEN RETURN END IF
	LET g_ordHead.order_datetime = CURRENT
-- Insert Order Here

	BEGIN WORK
	INSERT INTO ord_head VALUES g_ordHead.* 
	LET g_ordHead.order_number = SQLCA.SQLERRD[2] -- Fetch SERIAL order num
	LET m_pay.order_number = g_ordHead.order_number
	INSERT INTO ord_payment VALUES(m_pay.*)
	FOR l_row = 1 TO g_detailArray.getLength()
		IF g_detailArray[ l_row ].stock_code IS NOT NULL THEN
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
	COMMIT WORK -- Commit and end transaction.
	RUN "fglrun printInvoices.42r S 1 "||g_ordHead.order_number||" ordent-4.4rp Image bg 0 ord"||g_ordHead.order_number||"-"

	OPEN WINDOW inv WITH FORM "webOE_inv"
	DISPLAY "ord"||g_ordHead.order_number||"-0001.png" TO inv
	MENU
		ON ACTION close EXIT MENU
		ON ACTION exit EXIT MENU
	END MENU
	CLOSE WINDOW inv

	CALL initAll()

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION initAll()

	INITIALIZE g_cust.* TO NULL
	INITIALIZE g_ordHead.* TO NULL
	INITIALIZE m_pay.* TO NULL
	LET g_ordHead.items = 0
	LET g_ordHead.order_datetime = CURRENT
	LET g_custcode = "Guest"
	LET g_custname = "Guest"
	CALL g_detailArray.clear()
	LET m_pay.del_type = "0"
	LET m_pay.del_amount = POST_0
	LET m_pay.payment_type = "C"
	LET m_pay.card_type = "V"
	CALL recalcOrder()
	DISPLAY g_custname TO custname

END FUNCTION