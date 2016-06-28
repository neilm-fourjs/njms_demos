
#+
#+ $Id: ordent.inc 439 2010-10-11 15:39:20Z  $
&include "schema.inc"
TYPE t_detailLine
	RECORD
		stock_code LIKE ord_detail.stock_code,
		barcode LIKE stock.barcode,
		description LIKE stock.description,
		pack_flag LIKE stock.pack_flag,
		price LIKE stock.price,
		stock INTEGER,
		quantity LIKE ord_detail.quantity,
		disc_percent LIKE ord_detail.disc_percent,
		disc_value LIKE ord_detail.disc_value,
		tax_code LIKE ord_detail.tax_code,
		tax_rate LIKE ord_detail.tax_rate,
		tax_value LIKE ord_detail.tax_value,
		gross_value DECIMAL(12,2), 
		nett_value DECIMAL(12,2),
		accepted BOOLEAN
	END RECORD

TYPE t_detailLine_tree
	RECORD
		parentid SMALLINT,
		id SMALLINT,
		stock_code LIKE ord_detail.stock_code,
		barcode LIKE stock.barcode,
		description LIKE stock.description,
		pack_flag LIKE stock.pack_flag,
		price LIKE stock.price,
		stock INTEGER,
		quantity LIKE ord_detail.quantity,
		disc_percent LIKE ord_detail.disc_percent,
		disc_value LIKE ord_detail.disc_value,
		tax_code LIKE ord_detail.tax_code,
		tax_rate LIKE ord_detail.tax_rate,
		tax_value LIKE ord_detail.tax_value,
		gross_value DECIMAL(12,2), 
		nett_value DECIMAL(12,2),
		accepted BOOLEAN
	END RECORD

TYPE t_packItem
	RECORD
		stock_code LIKE pack_items.stock_code,
		qty LIKE pack_items.qty,
		price LIKE pack_items.price,
		cost LIKE pack_items.cost,
		tax_code LIKE pack_items.tax_code,
		disc_code LIKE pack_items.disc_code,
		description LIKE stock.description
	END RECORD

DEFINE stk RECORD LIKE stock.*

DEFINE detailArray_tree DYNAMIC ARRAY OF t_detailLine_tree
DEFINE m_user RECORD LIKE sys_users.*

CONSTANT VAT_RATE = 17.5
CONSTANT POST_0 = 5.50
CONSTANT POST_1 = 3.50
CONSTANT POST_2 = 2.50
CONSTANT POST_3 = 0

GLOBALS
	DEFINE g_cust RECORD LIKE customer.*
	DEFINE g_ordHead RECORD LIKE ord_head.*
	DEFINE g_detailArray DYNAMIC ARRAY OF t_detailLine
	DEFINE g_custcode LIKE customer.customer_code
	DEFINE g_custname LIKE customer.customer_name
END GLOBALS
--DEFINE packItem t_packItem
