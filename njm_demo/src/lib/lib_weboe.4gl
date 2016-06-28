
&include "schema.inc"
&include "ordent.inc"

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
	DEFINE l_ah SMALLINT

	IF g_custcode != "Guest" THEN
		IF fgl_winQuestion("Confirm","Confirm signout","No","Yes|No","question",0) = "No" THEN
			RETURN
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
		ON KEY(f12) LET l_em = "njm@njm-projects.com" LET l_pwd = "12njm"
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
&ifdef CLOUD
				CALL cl_addUser(m_VARCODE, m_VARPASS, 0, l_cust.customer_code , l_cust.web_passwd, 
							l_cust.email, "webOE", "A",1, TRUE)
					RETURNING m_soapStatus, cl_addUserResponse.stat, cl_addUserResponse.mesg
				CALL soapStatus()
&endif
			ELSE
				SELECT * INTO g_cust.* FROM customer
				WHERE email = l_em AND web_passwd = l_pwd
				IF STATUS = NOTFOUND THEN
					DISPLAY "Invalid Login!" TO msg
					NEXT FIELD l_em
				END IF
			END IF
			LET g_custcode = g_cust.customer_code
			LET g_custname = g_cust.contact_name
			CALL oe_setHead( g_cust.customer_code,g_cust.del_addr,g_cust.inv_addr )
	END INPUT
	CLOSE WINDOW weboe_signin
	IF int_flag THEN 
		LET int_flag = FALSE
		LET g_custname = "Guest"
		LET g_custcode = "Guest"
	END IF
	CALL setSignInAction()
	DISPLAY g_custname TO custname
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION setSignInAction()
	DEFINE f ui.Form
	DEFINE d ui.Dialog
	LET d = ui.Dialog.getCurrent()
	LET f = d.getForm()
	IF g_custcode = "Guest" THEN
		DISPLAY "SignIn"
		CALL f.setElementText("signin","Sign In")
	ELSE
		DISPLAY "SignOut"
		CALL f.setElementText("signin","Sign Out")
	END IF
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
FUNCTION soapStatus()
&ifdef CLOUD
	IF m_soapStatus = 0 THEN RETURN END IF
	CALL fgl_winMessage("WS Error","An occured with the web service call\nSoap Status:"||m_soapStatus||"\nResponse Status:"||cl_addUserResponse.stat||"\nMessage:"||cl_addUserResponse.mesg,"exclamation")
&endif
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION viewb()
	DEFINE l_co BOOLEAN

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
		BEFORE INPUT
			CALL setSignInAction()
	END INPUT
	CLOSE WINDOW basket
	CALL recalcOrder()
	IF l_co THEN CALL gotoco() END IF
END FUNCTION