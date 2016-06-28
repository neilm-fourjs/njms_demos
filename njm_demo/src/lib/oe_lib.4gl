
#+ General library code
#+
#+ $Id: oe_lib.4gl 688 2011-05-31 09:58:14Z  $

&include "schema.inc"
&include "ordent.inc"
&include "genero_lib1.inc"

FUNCTION oe_cursors()
GL_MODULE_ERROR_HANDLER
	DECLARE cb_sc CURSOR FOR SELECT * FROM stock_cat

	DECLARE fetch_stock_cur CURSOR FROM " SELECT * FROM stock WHERE stock_code = ?"

	DECLARE getDisc CURSOR FROM "SELECT * FROM disc WHERE stock_disc = ? AND customer_disc = ?"

	DECLARE packCur CURSOR FROM 
		"SELECT p.*,s.description FROM pack_items p,stock s WHERE p.pack_code = ? AND s.stock_code = p.stock_code"
END FUNCTION


#+ Get a Customer or return null.
#+
#+ @return The customer record or null.
FUNCTION getCust() 
	DEFINE arr DYNAMIC ARRAY OF RECORD 
			customer_code LIKE customer.customer_code,
			customer_name LIKE customer.customer_name
		END RECORD
	DEFINE wher STRING
	DISPLAY __LINE__," hello"
	OPEN WINDOW getcust WITH FORM "getcust"

	WHILE TRUE
		LET int_flag = FALSE
		CONSTRUCT BY NAME wher ON customer_code, customer_name
		IF int_flag THEN EXIT WHILE END IF
		IF NOT int_flag THEN 
			PREPARE cstpre FROM "SELECT customer_code,customer_name FROM customer WHERE "||wher
			IF wher IS NULL THEN DISPLAY "where is NULL!" END IF
			DECLARE cstcur CURSOR FOR cstpre
			CALL arr.clear()
			FOREACH cstcur INTO arr[ arr.getLength() + 1]. *
			END FOREACH
			CALL arr.deleteElement( arr.getLength() )
			LET int_flag = FALSE
			IF arr.getLength() > 0 THEN
				DISPLAY ARRAY arr TO arr.*
			ELSE
				CALL fgl_winMessage("Warning","No rows found","exclamation")
				CONTINUE WHILE
			END IF
		END IF
		IF NOT int_flag THEN EXIT WHILE END IF
	END WHILE
	CLOSE WINDOW getcust

	IF int_flag THEN
		LET int_flag = FALSE
		INITIALIZE g_cust.* TO NULL
		RETURN
	END IF
	SELECT * INTO g_cust.* FROM customer WHERE customer_code = arr[ arr_curr() ].customer_code

END FUNCTION
----------------------------------------------------------------------------------
#+ Get a Stock item or return null.
#+
#+ @return The stock record or null.
FUNCTION getStock(filter)
	DEFINE filter VARCHAR(20) 
	DEFINE arr DYNAMIC ARRAY OF RECORD LIKE stock.*
	DEFINE sel VARCHAR(200)
	DEFINE wher STRING
	DEFINE x INTEGER

	OPEN WINDOW getstock WITH FORM "getstock"
	LET int_flag = FALSE
	IF filter IS NOT NULL THEN
		LET sel = "SELECT * FROM stock WHERE stock_code MATCHES '"||filter||"'"
	ELSE
		CONSTRUCT BY NAME wher ON stock_code,stock_cat,description
		LET sel = "SELECT * FROM stock WHERE "||wher
	END IF
	DISPLAY "sel:",sel
	IF NOT int_flag THEN
		PREPARE stk_pre FROM sel
		DECLARE stkcur CURSOR FOR stk_pre
		FOREACH stkcur INTO arr[ arr.getLength() + 1]. *
		END FOREACH
		CALL arr.deleteElement( arr.getLength() )
		LET int_flag = FALSE
		DISPLAY ARRAY arr TO arr.*
	END IF

	CLOSE WINDOW getstock
	LET x = arr_curr()
	IF x > arr.getLength() OR x < 1 THEN LET INT_FLAG = TRUE END IF
	IF int_flag THEN
		LET int_flag = FALSE
		INITIALIZE arr[1].* TO NULL
		RETURN arr[1].*
	END IF
	RETURN arr[ x ].*
END FUNCTION
-------------------------------------------------------------------------------
FUNCTION cb_stkcat( cb )
	DEFINE cb ui.ComboBox
	DEFINE sc RECORD LIKE stock_cat.*

	CALL cb.clear()
	FOREACH cb_sc INTO sc.*
		CALL cb.addItem(sc.catid, sc.cat_name CLIPPED)
	END FOREACH
END FUNCTION
--------------------------------------------------------------------------------
#+ Get the stock record and check it's stock level
#+
#+ @param l_row Index of array element to retreive product code from.
FUNCTION oe_getStockRec(l_row,l_verbose)
	DEFINE l_row,l_stat SMALLINT
	DEFINE l_verbose BOOLEAN
	DEFINE l_d RECORD LIKE disc.*

	INITIALIZE stk.* TO NULL
	TRY
		OPEN fetch_stock_cur USING g_detailArray[ l_row ].stock_code
	CATCH
		LET l_stat = STATUS
		DISPLAY "Failed:",l_stat
		IF l_stat = -263 THEN -- Row locked
			CALL fgl_winMessage("Error","That Stock item is currently locked by another user.","exclamation")
			RETURN FALSE
		END IF
		IF l_stat != 0 THEN
			CALL fgl_winMessage("Error","Error reading record.\n"||SQLERRMESSAGE,"exclamation")
			RETURN FALSE
		END IF
	END TRY

	FETCH fetch_stock_cur INTO stk.*
	IF STATUS = NOTFOUND THEN
		CALL fgl_winMessage("Error","Item not found.","exclamation")
		RETURN FALSE
	END IF
	CLOSE fetch_stock_cur

	IF stk.free_stock < 1 THEN
		CALL fgl_winMessage("Error","Item out of stock.","exclamation")
		RETURN FALSE
	END IF

	DISPLAY "Stk:",stk.disc_code," CST:",g_cust.disc_code
	OPEN getDisc USING stk.disc_code, g_cust.disc_code
	FETCH getDisc INTO l_d.* 
	IF STATUS = NOTFOUND THEN
		LET l_d.disc_percent = 0
	END IF
	LET g_detailArray[ l_row ].description = stk.description
	LET g_detailArray[ l_row ].stock = stk.free_stock
	LET g_detailArray[ l_row ].disc_percent = l_d.disc_percent
	LET g_detailArray[ l_row ].disc_value = stk.price * ( g_detailArray[ l_row ].disc_percent / 100 )

	IF g_detailArray[ l_row ].price IS NULL OR g_detailArray[ l_row ].price = 0 THEN
		LET g_detailArray[ l_row ].price = stk.price
	END IF
	IF g_detailArray[ l_row ].tax_code IS NULL THEN
		LET g_detailArray[ l_row ].tax_code = stk.tax_code
	END IF
	IF g_detailArray[ l_row ].tax_code = "1" THEN
		LET g_detailArray[ l_row ].tax_rate = VAT_RATE
		LET g_detailArray[ l_row ].tax_value = stk.price * ( g_detailArray[ l_row ].tax_rate / 100 )
	ELSE
		LET g_detailArray[ l_row ].tax_rate = 0
		LET g_detailArray[ l_row ].tax_value = 0
	END IF
	IF stk.pack_flag = "P" OR stk.pack_flag = "E" THEN
		LET g_detailArray[ l_row ].pack_flag = oe_showPack( stk.stock_code, l_verbose)
	END IF
	RETURN TRUE
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION oe_showPack( l_pc, l_verbose )
	DEFINE l_pc LIKE stock.stock_code
	DEFINE l_verbose BOOLEAN
	DEFINE l_pdesc LIKE stock.description
	DEFINE l_packs DYNAMIC ARRAY OF t_packItem
	DEFINE pf CHAR(1)
	SELECT description,pack_flag INTO l_pdesc, pf FROM stock WHERE stock_code = l_pc
	IF l_verbose THEN
		OPEN WINDOW pack WITH FORM "packshow"
		DISPLAY l_pc TO pack_code
		DISPLAY l_pdesc TO pack_desc
	END IF

	FOREACH packCur USING l_pc INTO l_pc,l_packs[l_packs.getLength()+1].*
	END FOREACH
	IF l_verbose THEN
		DIALOG ATTRIBUTE(UNBUFFERED)
			INPUT BY NAME pf ATTRIBUTES(WITHOUT DEFAULTS=TRUE)
			END INPUT
			DISPLAY ARRAY l_packs TO packs.*
			END DISPLAY
			ON ACTION close EXIT DIALOG
			ON ACTION cancel EXIT DIALOG
		END DIALOG
		CLOSE WINDOW pack
	END IF
	IF int_flag THEN LET int_flag = FALSE END IF
	RETURN pf
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION oe_explodePack(l_row)
	DEFINE l_row SMALLINT
	DEFINE l_packcode CHAR(8)
	DEFINE l_pack t_packItem
	DEFINE l_pack_qty INTEGER
	IF g_detailArray[ l_row ].pack_flag = "E" THEN -- Explode pack
		LET l_pack_qty = g_detailArray[ l_row ].quantity
		FOREACH packCur USING g_detailArray[ l_row ].stock_code
			INTO l_packcode,l_pack.*
			LET g_detailArray[ g_detailArray.getLength() + 1 ].stock_code = l_pack.stock_code
			LET g_detailArray[ g_detailArray.getLength() ].description = l_pack.description
			LET g_detailArray[ g_detailArray.getLength() ].quantity = l_pack.qty * l_pack_qty
			LET g_detailArray[ g_detailArray.getLength() ].price = l_pack.price
			LET g_detailArray[ g_detailArray.getLength() ].tax_code = l_pack.tax_code
			LET g_detailArray[ g_detailArray.getLength() ].accepted = TRUE
			IF oe_getStockRec( g_detailArray.getLength(), FALSE ) THEN
--
			ELSE
-- Shouldn't happen ??
			END IF
			LET g_detailArray[ g_detailArray.getLength() ].pack_flag = "e" -- exploded
			LET g_detailArray[ g_detailArray.getLength() ].nett_value = 0
			LET g_detailArray[ g_detailArray.getLength() ].gross_value = 0
		END FOREACH
	END IF
	CALL oe_calcOrderTot()
END FUNCTION
--------------------------------------------------------------------------------
#+ Calculate the line totals.
#+
#+ @param l_row Index of the row to calculate.
FUNCTION oe_calcLineTot(l_row)
	DEFINE l_row SMALLINT

	IF g_detailArray[ l_row ].price IS NULL THEN LET g_detailArray[ l_row ].price = 0 END IF
	IF g_detailArray[ l_row ].quantity IS NULL THEN LET g_detailArray[ l_row ].quantity = 0 END IF
	IF g_detailArray[ l_row ].disc_percent IS NULL THEN LET g_detailArray[ l_row ].disc_percent = 0 END IF
	IF g_detailArray[ l_row ].tax_rate IS NULL THEN LET g_detailArray[ l_row ].tax_rate = 0 END IF

	LET g_detailArray[ l_row ].gross_value = g_detailArray[ l_row ].price * g_detailArray[ l_row ].quantity
	LET g_detailArray[ l_row ].disc_value = g_detailArray[ l_row ].gross_value * ( g_detailArray[ l_row ].disc_percent / 100)
	LET g_detailArray[ l_row ].nett_value = g_detailArray[ l_row ].gross_value - g_detailArray[ l_row ].disc_value
	LET g_detailArray[ l_row ].tax_value = g_detailArray[ l_row ].nett_value * ( g_detailArray[ l_row ].tax_rate / 100 )
	LET g_detailArray[ l_row ].nett_value =  g_detailArray[ l_row ].nett_value + g_detailArray[ l_row ].tax_value 
{
	DISPLAY "Gross:",g_detailArray[ l_row ].gross_value
	DISPLAY "Disc:",g_detailArray[ l_row ].disc_value
	DISPLAY "Tax:",g_detailArray[ l_row ].tax_value
	DISPLAY "Nett:",g_detailArray[ l_row ].nett_value
}
END FUNCTION
--------------------------------------------------------------------------------
#+ Calculate the order totals.
FUNCTION oe_calcOrderTot()
	DEFINE l_row SMALLINT

	LET g_ordHead.items = 0
	LET g_ordHead.total_qty = 0
	LET g_ordHead.total_disc = 0
	LET g_ordHead.total_gross = 0
	LET g_ordHead.total_nett = 0
	LET g_ordHead.total_tax = 0
	FOR l_row = 1 TO g_detailArray.getLength()
		IF g_detailArray[ l_row ].stock_code IS NULL THEN CONTINUE FOR END IF
		CALL oe_calcLineTot(l_row)

		LET g_ordHead.items = g_ordHead.items + 1
		LET g_ordHead.total_gross = g_ordHead.total_gross + g_detailArray[ l_row ].gross_value
		LET g_ordHead.total_nett = g_ordHead.total_nett + g_detailArray[ l_row ].nett_value
		LET g_ordHead.total_qty = g_ordHead.total_qty + g_detailArray[ l_row ].quantity
		LET g_ordHead.total_disc = g_ordHead.total_disc + g_detailArray[ l_row ].disc_value
		LET g_ordHead.total_tax = g_ordHead.total_tax + g_detailArray[ l_row ].tax_value
	END FOR

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION oe_setHead( cc, da, ia )
	DEFINE cc LIKE customer.customer_code
	DEFINE da, ia LIKE addresses.rec_key
	DEFINE inv_ad, del_ad RECORD LIKE addresses.*

	LET g_ordHead.customer_code = cc
	SELECT * INTO del_ad.* FROM addresses WHERE rec_key = da
	SELECT * INTO inv_ad.* FROM addresses WHERE rec_key = ia
	LET g_ordHead.customer_name = cc
	LET g_ordHead.del_address1 = del_ad.line1
	LET g_ordHead.del_address2 = del_ad.line2
	LET g_ordHead.del_address3 = del_ad.line3
	LET g_ordHead.del_address4 = del_ad.line4
	LET g_ordHead.del_address5 = del_ad.line5
	LET g_ordHead.del_postcode = del_ad.postal_code
	LET g_ordHead.inv_address1 = inv_ad.line1
	LET g_ordHead.inv_address2 = inv_ad.line2
	LET g_ordHead.inv_address3 = inv_ad.line3
	LET g_ordHead.inv_address4 = inv_ad.line4
	LET g_ordHead.inv_address5 = inv_ad.line5
	LET g_ordHead.inv_postcode = inv_ad.postal_code

END FUNCTION
--------------------------------------------------------------------------------