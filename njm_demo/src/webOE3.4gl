
#+ Web Order Entry Demo - by N.J.Martin neilm@4js.com
#+
#+ $Id: webOE.4gl 960 2016-06-13 14:39:50Z neilm $

IMPORT FGL lib_weboe

CONSTANT PRGNAME = "webOE3"
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
		qty1 INTEGER
	END RECORD

DEFINE m_vbox, m_grid_cats om.DomNode
DEFINE m_dialog ui.Dialog
DEFINE m_fields DYNAMIC ARRAY OF RECORD
		name STRING,
		type STRING
	END RECORD
	DEFINE m_form ui.Form
MAIN
	DEFINE l_test STRING
	DEFINE l_em LIKE customer.email
	DEFINE l_win ui.Window

	DEFINE l_cat SMALLINT

	CALL gl_setInfo(NULL, "njm_demo", "njm_demo", PRGNAME, PRGDESC, PRGAUTH)
	CALL gl_init(ARG_VAL(1),"weboe",TRUE)

	CALL gldb_connect(NULL)

	LET m_arg1 = ARG_VAL(1)
	IF m_arg1 IS NULL OR m_arg1 = " " THEN LET m_arg1 = "SDI" END IF
	LET m_arg2 = ARG_VAL(2)
	DISPLAY "webOE3 - arg2:",m_arg2
	IF m_arg2 IS NULL OR m_arg2 = " " THEN LET m_arg2 = "1" END IF
	LET m_dbtyp = gldb_getDBType()

	IF ui.Interface.getFrontEndName() != "GDC" THEN
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

	OPEN FORM weboe FROM "webOE3"
	DISPLAY FORM weboe

	LET l_win = ui.Window.getCurrent()
	LET m_form = l_win.getForm()
	LET m_vbox = m_form.findNode("VBox","main_vbox")

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
		WHERE stock.stock_cat = stock_cat.catid {AND stock_cat.catid != "ARMS"}
   ORDER BY stock_cat.cat_name
	FOREACH sc_cur INTO m_stock_cats[ m_stock_cats.getLength() + 1 ].*
	END FOREACH
	CALL m_stock_cats.deleteElement( m_stock_cats.getLength() )

	CALL build_cats()

	LET l_cat = 1

	WHILE l_cat > 0
		CALL getItems( m_stock_cats[ l_cat ].id )
		LET l_cat = dynDiag()
	END WHILE

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
		LET m_items[ m_items.getLength() + 1 ].stock_code1 = l_stk.stock_code
		LET m_items[ m_items.getLength() ].img1 = img.trim()
		LET m_items[ m_items.getLength() ].desc1 = mkDesc( l_stk.*)
		LET m_items[ m_items.getLength() ].qty1 = 0
	END FOREACH

	CALL build_grids()

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
FUNCTION recalcOrder()
	DEFINE x,y SMALLINT
	DEFINE l_d ui.Dialog

	CALL oe_calcOrderTot()

	DISPLAY BY NAME g_ordHead.total_qty,
			g_ordHead.total_gross,
			g_ordHead.total_disc,
			g_ordHead.total_tax,
			g_ordHead.total_nett

	FOR x = 1 TO m_items.getLength()
		LET m_items[x].qty1 = 0
		FOR y = 1 TO g_detailArray.getLength()
			IF m_items[x].stock_code1 = g_detailArray[y].stock_code THEN
				LET m_items[x].qty1 = g_detailArray[y].quantity
			END IF
		END FOR
	END FOR

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
FUNCTION build_cats()
	DEFINE n om.DomNode
	DEFINE x,len SMALLINT

	LET m_grid_cats = m_form.findNode("Group","cats")
	DISPLAY "Build cats"
	LET len = 5
	FOR x = 1 TO m_stock_cats.getLength()
		IF LENGTH( m_stock_cats[x].desc ) > len THEN LET len = LENGTH( m_stock_cats[x].desc ) END IF
	END FOR
	FOR x = 1 TO m_stock_cats.getLength()
		LET n = m_grid_cats.createChild("Button")
		CALL n.setAttribute("name", "cat"||x)
		CALL n.setAttribute("text", "  "||m_stock_cats[x].desc CLIPPED||"  " )
		CALL n.setAttribute("image", "products/"||DOWNSHIFT( m_stock_cats[x].id ) CLIPPED )
		CALL n.setAttribute("sizePolicy","fixed")
		CALL n.setAttribute("gridWidth", len)
		CALL n.setAttribute("width", len)
		CALL n.setAttribute("gridHeight", "1")
		CALL n.setAttribute("posY",x+1)
		CALL n.setAttribute("posX","1")
		CALL n.setAttribute("style", "big")
	END FOR
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION build_grids()
	DEFINE l_hbox, n,n1, ff om.DomNode
	DEFINE x,y, l_gw SMALLINT
	CONSTANT l_lab1_gwidth = 12
	CONSTANT l_lab2_gwidth = 3
	CONSTANT l_qty_gwidth = 6
	CONSTANT l_detbut_gwidth = 2

	LET l_gw = l_lab1_gwidth + 1
	DISPLAY "Build_grids"
	LET n = m_vbox.getParent()
	CALL n.removeChild( m_vbox )
	LET m_vbox = n.createChild("VBox")
	CALL m_vbox.setAttribute("name","main_vbox")
	CALL m_vbox.setAttribute("splitter","1")

	LET l_hbox = m_vbox.createChild("HBox")
	LET y = m_items.getLength()
	IF y MOD 4 THEN -- make sure we generate 4 grids across
		LET y = y + (4 - ( y MOD 4  ))
	END IF
	IF y < 8 THEN LET y = 8 END IF -- make sure we have at least 12 total
	FOR x = 1 TO y
		LET n = l_hbox.createChild("Group")
		IF x <= m_items.getLength() THEN
			CALL n.setAttribute("style", "griditemX")
		ELSE
			CALL n.setAttribute("style", "noborderX")
		END IF
		LET n = n.createChild("Grid")
		CALL n.setAttribute("gridWidth", l_gw)
		CALL n.setAttribute("gridHeight", "14")
		IF x <= m_items.getLength() THEN
			CALL n.setAttribute("style", "griditem")
		END IF

		LET n1 = n.createChild("Image")
		IF x <= m_items.getLength() THEN
			CALL n1.setAttribute("image", m_items[x].img1)
		END IF
		CALL n1.setAttribute("style", "bg_white noborder")
		CALL n1.setAttribute("sizePolicy","fixed")
		CALL n1.setAttribute("autoScale","1")

		CALL n1.setAttribute("gridWidth", l_gw-1)
		CALL n1.setAttribute("width", "150px")
		CALL n1.setAttribute("height", "150px")
		CALL n1.setAttribute("posY","1")
		CALL n1.setAttribute("posX","1")

		LET n1 = n.createChild("Label")
		IF x <= m_items.getLength() THEN
			CALL n1.setAttribute("text", m_items[x].desc1)
		ELSE
			CALL n1.setAttribute("text", "&nbsp;" )
		END IF
		CALL n1.setAttribute("gridWidth", l_lab1_gwidth)
		CALL n1.setAttribute("width", l_lab1_gwidth)
		CALL n1.setAttribute("gridHeight", "3")
		CALL n1.setAttribute("posY","5")
		CALL n1.setAttribute("posX","1")
		CALL n1.setAttribute("style", "html")

		LET n1 = n.createChild("Label")
		IF x <= m_items.getLength() THEN
			CALL n1.setAttribute("text","QTY:")
		END IF
		CALL n1.setAttribute("style", "bold")
		CALL n1.setAttribute("gridWidth",l_lab2_gwidth)
		CALL n1.setAttribute("width","4")
		CALL n1.setAttribute("sizePolicy","fixed")
		CALL n1.setAttribute("posY","10")
		CALL n1.setAttribute("posX","1")

		IF x <= m_items.getLength() THEN
			LET ff = n.createChild("FormField")
			CALL ff.setAttribute("name","formonly.qty"||x)
			CALL ff.setAttribute("colName","qty"||x)
			LET n1 = ff.createChild("ButtonEdit")
			CALL n1.setAttribute("gridWidth",l_qty_gwidth)
			CALL n1.setAttribute("width",l_qty_gwidth)
			CALL n1.setAttribute("action","add1")
			CALL n1.setAttribute("posY","10")
			CALL n1.setAttribute("posX",l_lab2_gwidth)
			CALL n1.setAttribute("style", "bold")

			LET n1 = n.createChild("Button")
			CALL n1.setAttribute("name","detlnk"||x)
			CALL n1.setAttribute("gridWidth",l_detbut_gwidth)
			CALL n1.setAttribute("width",l_detbut_gwidth)
			CALL n1.setAttribute("image", "fa-info-circle")
			CALL n1.setAttribute("posY","10")
			CALL n1.setAttribute("posX",l_lab2_gwidth+l_qty_gwidth)
		END IF
		DISPLAY "Grid x:",x, " y:",y, " MOD4:",( x MOD 4 ), " len:",m_items.getLength()
		IF NOT x MOD 4 THEN
			LET l_hbox = m_vbox.createChild("HBox")
		END IF
	END FOR

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION dynDiag()
	DEFINE x SMALLINT
	DEFINE l_field, l_evt STRING

	CALL m_fields.clear()
	FOR x = 1 TO m_items.getLength()
		LET m_fields[m_fields.getLength()+1].name = "qty"||x
		LET m_fields[m_fields.getLength()].type = "INTEGER"
		--LET m_fields[m_fields.getLength()+1].name = "det"||x
		--LET m_fields[m_fields.getLength()].type = "INTEGER"
	END FOR

	{FOR x = 1 TO m_fields.getLength()
		DISPLAY "Fields:",m_fields[x].name,":",m_fields[x].type
	END FOR}

	CALL ui.Dialog.setDefaultUnbuffered(TRUE)
	LET m_dialog = ui.Dialog.createInputByName(m_fields)

	CALL m_dialog.addTrigger("ON ACTION close")
	CALL m_dialog.addTrigger("ON ACTION add1")
	CALL m_dialog.addTrigger("ON ACTION viewb")
	CALL m_dialog.addTrigger("ON ACTION signin")
	CALL m_dialog.addTrigger("ON ACTION gotoco")
	CALL m_dialog.addTrigger("ON ACTION cancel")	
	FOR x = 1 TO m_items.getLength()
		CALL m_dialog.addTrigger("ON ACTION detlnk"||x)
	END FOR
	FOR x = 1 TO m_stock_cats.getLength()
		CALL m_dialog.addTrigger("ON ACTION cat"||x)
	END FOR
	CALL m_dialog.setActionActive("viewb",FALSE)
	CALL m_dialog.setActionActive("gotoco",FALSE)
	CALL setSignInAction()
	LET int_flag = FALSE
	WHILE TRUE
		LET l_evt = m_dialog.nextEvent()

		IF l_evt MATCHES "ON ACTION cat*" THEN
			RETURN l_evt.subString(14, l_evt.getLength())
		END IF

		IF l_evt MATCHES "ON ACTION detlnk*" THEN
			LET x = l_evt.subString(17, l_evt.getLength())
			CALL detLnk( m_items[x].stock_code1,
					m_items[x].desc1,
					m_items[x].img1,
					m_items[x].qty1 )
			CALL recalcOrder()
		END IF

		CASE l_evt
			WHEN "ON CHANGE qty1"
				LET l_field = m_dialog.getCurrentItem()
				LET x = l_field.subString(4, l_field.getLength())
				DISPLAY "add1 GI:",l_field," X:",x
				CALL detLine(m_items[x].stock_code1,  m_dialog.getFieldValue("qty"||x))
				CALL m_dialog.setFieldValue("qty"||x, m_items[x].qty1)

			WHEN "ON ACTION add1"
				LET l_field = m_dialog.getCurrentItem()
				LET x = l_field.subString(4, l_field.getLength())
				DISPLAY "add1 GI:",l_field," X:",x
				CALL detLine(m_items[x].stock_code1,m_items[x].qty1+1)
				CALL m_dialog.setFieldValue("qty"||x, m_items[x].qty1)

			WHEN "ON ACTION close"
				LET int_flag = TRUE
				EXIT WHILE

			WHEN "ON ACTION cancel"
				LET int_flag = TRUE
				EXIT WHILE

			WHEN "ON ACTION signin" 
				CALL lib_weboe.signin()

			WHEN "ON ACTION viewb" CALL lib_weboe.viewb()
			WHEN "ON ACTION gotoco" CALL gotoco()
		END CASE
	END WHILE
	IF int_flag THEN LET int_flag = FALSE END IF
	RETURN 0
END FUNCTION