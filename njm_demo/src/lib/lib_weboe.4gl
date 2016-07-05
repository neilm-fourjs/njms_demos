
&include "schema.inc"
&include "ordent.inc"

DEFINE m_pay RECORD LIKE ord_payment.*

FUNCTION build_sqls()
	DECLARE stkcur2 CURSOR FROM "SELECT * FROM stock WHERE stock_code = ?"
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION detLnk(l_sc, l_det, l_img, l_qty )
	DEFINE l_sc LIKE stock.stock_code
	DEFINE l_det,l_img STRING
	DEFINE l_qty SMALLINT
	DEFINE co BOOLEAN
	OPEN WINDOW webOE_det WITH FORM "webOE_det"
	DISPLAY BY NAME l_det,l_img
	DISPLAY g_custname TO custname
	LET co = FALSE
	MENU
		BEFORE MENU
			CALL recalcOrder()
			CALL setSignInAction()
		ON ACTION signin CALL signin()
		ON ACTION viewb CALL viewb()
		ON ACTION gotoco LET co = TRUE EXIT MENU
		ON ACTION add CALL detLine(l_sc,l_qty+1)
		ON ACTION cancel EXIT MENU
	END MENU
	CLOSE WINDOW webOE_det
	CALL recalcOrder()
	IF co THEN CALL gotoco() END IF
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION signin()
	DEFINE l_em LIKE customer.email
	DEFINE l_pwd LIKE customer.web_passwd
	DEFINE l_cust_name LIKE customer.customer_name
	DEFINE l_cont_name LIKE customer.contact_name
	DEFINE l_email LIKE customer.email
	DEFINE l_password1 LIKE customer.web_passwd
	DEFINE l_password2 LIKE customer.web_passwd
	DEFINE l_form ui.Form
	DEFINE l_newuser BOOLEAN
	DEFINE l_cust RECORD LIKE customer.*
	DEFINE l_ah, l_result SMALLINT
	DEFINE l_cookie STRING

	IF g_custcode != "Guest" THEN
		IF fgl_winQuestion("Confirm","Confirm signout","No","Yes|No","question",0) = "No" THEN
			RETURN
		END IF
		IF UPSHIFT(ui.Interface.getFrontEndName()) != "GDC" THEN
			LET l_cookie = "guest"
			CALL ui.Interface.FrontCall("session","setvar",["login",l_cookie],l_result)
			DISPLAY "login: Setting cookie:",l_cookie, " Ret:",l_result
		END IF
		CALL initAll()
		RETURN
	END IF

	OPEN WINDOW weboe_signin WITH FORM "webOE_signin"
	LET int_flag = FALSE
	LET l_newuser = FALSE
	INPUT BY NAME l_em,l_pwd,
							 l_cust_name,
							 l_cont_name,
							 l_email,
							 l_password1,
							 l_password2 ATTRIBUTE(UNBUFFERED)

		BEFORE INPUT 
			LET l_form = DIALOG.getForm()
		ON ACTION newuser
			CALL l_form.setElementHidden("newuser",FALSE)
			CALL DIALOG.setFieldActive("l_em",FALSE)
			CALL DIALOG.setFieldActive("l_pwd",FALSE)
			LET l_newuser = TRUE
			CALL DIALOG.setActionActive("newuser",FALSE)

		AFTER FIELD l_pwd
			LET l_password1 = l_pwd
			LET l_password2 = l_pwd
		AFTER FIELD l_email
			SELECT customer_code,customer_name
					FROM customer WHERE email = l_email
			IF STATUS != NOTFOUND THEN
				DISPLAY "Email address is already registered" TO msg
				NEXT FIELD l_email
			END IF
			DISPLAY "" TO msg
		AFTER FIELD l_password1
			DISPLAY "" TO msg
		AFTER INPUT
			IF int_flag THEN EXIT INPUT END IF
			IF l_newuser THEN
				IF l_password1 != l_password2 THEN
					DISPLAY "Passwords don't match!" TO msg
					LET l_password1 = NULL
					LET l_password2 = NULL
					NEXT FIELD l_password1
				END IF
				LET l_cust.customer_name = l_cust_name
				LET l_cust.contact_name = l_cont_name
				LET l_cust.email = l_email
				LET l_cust.web_passwd = l_password1
				SELECT COUNT(*) INTO l_ah FROM customer WHERE customer_code MATCHES "ah*"
				IF l_ah IS NULL THEN LET l_ah = 0 END IF
				LET l_cust.customer_code = "ah"||((l_ah  + 1) USING "&&&&&&")
				LET l_cust.del_addr = 0
				LET l_cust.inv_addr = 0
				LET l_cust.outstanding_amount = 0
				LET l_cust.total_invoices = 0
				LET l_cust.credit_limit = 0
				INSERT INTO customer VALUES(l_cust.*)
				LET l_em = l_email
				LET l_pwd = l_password1
			END IF

			SELECT * INTO g_cust.* FROM customer
			WHERE email = l_em AND web_passwd = l_pwd
			IF STATUS = NOTFOUND THEN
				DISPLAY "Invalid Login!" TO msg
				NEXT FIELD l_em
			END IF

			CALL logaccess( TRUE, l_em )
			LET g_custcode = g_cust.customer_code
			LET g_custname = g_cust.contact_name
			CALL oe_setHead( g_cust.customer_code,g_cust.del_addr,g_cust.inv_addr )
	END INPUT
	CLOSE WINDOW weboe_signin
	IF int_flag THEN 
		LET int_flag = FALSE
		LET g_custname = "Guest"
		LET g_custcode = "Guest"
	ELSE
		IF UPSHIFT(ui.Interface.getFrontEndName()) != "GDC" THEN
			LET l_cookie = g_custcode
			CALL ui.Interface.FrontCall("session","setvar",["login",l_cookie],l_result)
			DISPLAY "login: Setting cookie:",l_cookie, " Ret:",l_result
		END IF
	END IF
	CALL setSignInAction()

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION setSignInAction()
	DEFINE f ui.Form
	DEFINE d ui.Dialog
	LET d = ui.Dialog.getCurrent()
	LET f = d.getForm()
	IF g_custcode = "Guest" THEN
		CALL f.setElementText("signin","Sign In")
	ELSE
		CALL f.setElementText("signin","Sign Out")
	END IF
	DISPLAY g_custname TO custname
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION detLine(l_sc,l_qty)
	DEFINE l_sc LIKE stock.stock_code
	DEFINE l_qty, l_row INTEGER
	DEFINE l_stk RECORD LIKE stock.*

	DISPLAY "detline:", l_sc, ":",l_qty
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
FUNCTION mkDesc( l_stk )
	DEFINE l_stk RECORD LIKE stock.*
	DEFINE l_desc STRING

&define TITLON(sz) "<B STYLE=\"font-size: "||sz||"pt;\">"
&define TITLOFF "</B>"
	IF l_stk.free_stock IS NULL THEN LET l_stk.free_stock = 0 END IF
	LET l_desc = TITLON(10)||(l_stk.description CLIPPED)||TITLOFF||"<BR>"
	LET l_desc = l_desc.append(TITLON(8)||"Price: "||TITLOFF||l_stk.price||"<BR>")
	LET l_desc = l_desc.append(TITLON(8)||"Stock: "||TITLOFF||l_stk.free_stock||"<BR>")
	DISPLAY "Desc:"||l_desc
	RETURN l_desc
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION viewb()
	DEFINE l_co BOOLEAN
	DEFINE l_f ui.Form
	OPEN WINDOW basket WITH FORM "webOE_b"
	CALL recalcOrder()
	DISPLAY g_custname TO custname

	LET l_co = FALSE
	INPUT ARRAY g_detailArray FROM dets.* ATTRIBUTE(UNBUFFERED, WITHOUT DEFAULTS,
				DELETE ROW=FALSE,INSERT ROW=FALSE,APPEND ROW=FALSE)
		ON ACTION delete
			CALL g_detailArray.deleteElement( arr_curr() )
			CALL recalcOrder()
		AFTER FIELD qty
			CALL oe_calcLineTot(arr_curr())
			CALL recalcOrder()
		ON ACTION signin
			CALL signin()
		ON ACTION gotoco LET l_co = TRUE EXIT INPUT
		ON ACTION next EXIT INPUT
		BEFORE INPUT
			CALL setSignInAction()
			LET l_f = DIALOG.getForm()
			CALL l_f.setElementText("next","Continue Browsing Items")
	END INPUT
	CLOSE WINDOW basket
	CALL recalcOrder()
	IF l_co THEN CALL gotoco() END IF
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION oe_uiUpdate()
	DEFINE l_d ui.Dialog

	CALL oe_calcOrderTot()

	DISPLAY BY NAME 
			g_ordHead.total_qty,
			g_ordHead.total_gross,
			g_ordHead.total_disc,
			g_ordHead.total_tax,
			g_ordHead.total_nett

	DISPLAY "Your basket: "||g_ordHead.total_qty||" Items, Value: "||g_ordHead.total_nett
	DISPLAY "Your basket: "||g_ordHead.total_qty||" Items, Value: "||g_ordHead.total_nett TO status

	LET l_d = ui.Dialog.getCurrent()
	IF l_d IS NOT NULL THEN
		TRY -- actions maybe not be in current dialog!
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
	DEFINE l_add RECORD LIKE addresses.*
	DEFINE del_amt LIKE ord_payment.del_amount
	IF g_custcode = "Guest" THEN
		CALL signin()
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
	IF g_cust.del_addr > 0 THEN
		SELECT * INTO l_add.* FROM addresses WHERE rec_key = g_cust.del_addr
		LET g_ordHead.del_address1 = l_add.line1
		LET g_ordHead.del_address2 = l_add.line2
		LET g_ordHead.del_address3 = l_add.line3
		LET g_ordHead.del_address4 = l_add.line4
		LET g_ordHead.del_address5 = l_add.line5
		LET g_ordHead.del_postcode = l_add.postal_code
	END IF
	IF g_cust.inv_addr > 0 THEN
		SELECT * INTO l_add.* FROM addresses WHERE rec_key = g_cust.inv_addr
	END IF
-- will be del_addr if inv addr not found.
	LET g_ordHead.inv_address1 = l_add.line1
	LET g_ordHead.inv_address2 = l_add.line2
	LET g_ordHead.inv_address3 = l_add.line3
	LET g_ordHead.inv_address4 = l_add.line4
	LET g_ordHead.inv_address5 = l_add.line5
	LET g_ordHead.inv_postcode = l_add.postal_code

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

	IF g_cust.del_addr = 0 THEN
		INSERT INTO addresses VALUES(0,g_ordHead.del_address1, g_ordHead.del_address2, g_ordHead.del_address3, g_ordHead.del_address4, g_ordHead.del_address5, g_ordHead.del_postcode,"")
		LET g_cust.del_addr = SQLCA.sqlerrd[2]
		UPDATE customer SET del_addr = g_cust.del_addr WHERE customer_code = g_cust.customer_code
	END IF
	IF g_cust.inv_addr = 0 THEN
		INSERT INTO addresses VALUES(0,g_ordHead.inv_address1, g_ordHead.inv_address2, g_ordHead.inv_address3, g_ordHead.inv_address4, g_ordHead.inv_address5, g_ordHead.inv_postcode,"")
		LET g_cust.inv_addr = SQLCA.sqlerrd[2]
		UPDATE customer SET inv_addr = g_cust.inv_addr WHERE customer_code = g_cust.customer_code
	END IF

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
--------------------------------------------------------------------------------
FUNCTION logaccess( l_new, l_email )
	CONSTANT C_VER = 2
	DEFINE l_new BOOLEAN
	DEFINE l_email CHAR(60)
	DEFINE l_ver SMALLINT
	DEFINE l_wu RECORD
			wu_tabver SMALLINT,
			wu_email CHAR(60),
			wu_new_user SMALLINT,
			wu_when DATETIME YEAR TO SECOND,
			wu_fe CHAR(10),
			wu_fever CHAR(10),
			wu_gbc CHAR(20),
			wu_gbc_bootstrap CHAR(50),
			wu_gbc_url_prefix CHAR(50),
			wu_gas_addr CHAR(50),
			wu_host CHAR(50),
			wu_referer CHAR(200),
			wu_user_agent CHAR(200),
			wu_remote_addr CHAR(50)
		END RECORD
	
	TRY
		SELECT MAX(wu_tabver) INTO l_ver FROM web_access
	CATCH
		LET l_ver = 0
	END TRY
	IF l_ver != C_VER THEN
		IF l_ver > 0 THEN
			TRY
				DROP TABLE web_access
			CATCH
			END TRY
		END IF
		CREATE TABLE web_access (
			wu_tabver SMALLINT,
			wu_email CHAR(60),
			wu_new_user SMALLINT,
			wu_when DATETIME YEAR TO SECOND,
			wu_fe CHAR(10),
			wu_fever CHAR(10),
			wu_gbc CHAR(20),
			wu_gbc_bootstrap CHAR(50),
			wu_gbc_url_prefix CHAR(50),
			wu_gas_addr CHAR(50),
			wu_host CHAR(50),
			wu_referer CHAR(200),
			wu_user_agent CHAR(200),
			wu_remote_addr CHAR(50)
		)
		LET l_ver = C_VER
	END IF

	LET l_wu.wu_tabver = C_VER
	LET l_wu.wu_email = l_email
	LET l_wu.wu_new_user = l_new
	LET l_wu.wu_when = CURRENT
	LET l_wu.wu_fe = ui.Interface.getFrontEndName()
	LET l_wu.wu_fever = ui.Interface.getFrontEndVersion()
	LET l_wu.wu_gas_addr = fgl_getEnv("FGL_VMPROXY_GAS_ADDRESS")
	LET l_wu.wu_gbc = fgl_getEnv("GBC")
	LET l_wu.wu_gbc_bootstrap = fgl_getEnv("GBC_BOOTSTRAP")
	LET l_wu.wu_gbc_url_prefix = fgl_getEnv("GBC_URL_PREFIX")
	LET l_wu.wu_host = fgl_getEnv("FGL_WEBSERVER_HTTP_HOST")
	LET l_wu.wu_referer = fgl_getEnv("FGL_WEBSERVER_HTTP_REFERER")
	LET l_wu.wu_user_agent = fgl_getEnv("FGL_WEBSERVER_HTTP_USER_AGENT")
	LET l_wu.wu_remote_addr = fgl_getEnv("FGL_WEBSERVER_REMOTE_ADDR")

	INSERT INTO web_access VALUES(l_wu.*)

END FUNCTION