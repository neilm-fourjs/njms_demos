{ CVS Header
$Author: test4j $
$Date: 2007/07/12 16:42:43 $
$Revision: 208 $
$Source: /usr/home/test4j/cvs/all/demos/dbquery/src/dbquery.inc,v $
$Log: dbquery.inc,v $
Revision 1.24  2007/07/12 16:42:43  test4j

Changes for built in precompiler

Revision 1.23  2006/07/21 11:34:25  test4j

restructures make

Revision 1.22  2006/03/13 14:40:21  test4j

cvs tags

Revision 1.21  2006/03/03 17:14:40  test4j

updated library code and changed debug to genero_lib debug.

Revision 1.20  2006/01/12 17:20:57  test4j

Make file should work on DOS, started on other DOS compat issues

Revision 1.19  2005/11/14 16:55:30  test4j

Changed to use standard library code.

Revision 1.18  2005/10/04 17:02:01  test4j

Added driver, so can load odi driver at runtime.

Revision 1.17  2005/08/05 15:59:36  test4j

new build

Revision 1.17  2005/08/05 16:01:17  test4j

New release and tidied some bits.

Revision 1.16  2005/08/04 14:18:43  test4j
*** empty log message ***

Revision 1.15  2005/05/10 14:42:35  test4j

CVS header added.

}

CONSTANT copyright = "DBQuery by N.J.Martin neilm@4js.com"
CONSTANT max_dsp_cols = 100 -- Max columns per table
CONSTANT max_col_len = 150  -- Max column length
CONSTANT textedit_len = 60  -- Max field len before using TEXTEDIT
CONSTANT max_flds = 12      -- Max fields per form/tab
CONSTANT max_lst_cols = 6   -- Max columns for list routine

&include "build.inc"

GLOBALS
  DEFINE tables DYNAMIC ARRAY OF RECORD
    tabname CHAR(18)
  END RECORD

	DEFINE g_gl_version STRING
  
  DEFINE cols SMALLINT
  DEFINE tabs SMALLINT

  DEFINE xml_sch om.domdocument
  DEFINE xml_root om.domnode

	DEFINE db_arr DYNAMIC ARRAY OF CHAR(40)
	DEFINE db_cnt SMALLINT

	DEFINE choose_db SMALLINT
	DEFINE db_open SMALLINT
	DEFINE db_drv,db_nam,db_sch CHAR(20)
	DEFINE db_usr,db_psw,db_src,db_hst VARCHAR(20)
	DEFINE db_typ CHAR(3)
	DEFINE db_stat STRING

	DEFINE sel_tabname CHAR(18)

	DEFINE debug SMALLINT
	DEFINE dbgstr CHAR(20)

	DEFINE cwd,gver,gdcver,gdcip STRING
	DEFINE win32 SMALLINT


TYPE T_PRN_OPTS RECORD
		page_len SMALLINT,
		margin_l STRING,
		margin_r STRING,
		margin_t STRING,
		margin_b STRING,
		head_len SMALLINT,
		tail_len SMALLINT,
		paper_or STRING,
		paper_sz STRING,
		paper_ht STRING,
		paper_wd STRING,
		destinat STRING,
		filename STRING,
		final_ou STRING
	END RECORD

	DEFINE prn_opts T_PRN_OPTS
END GLOBALS

DEFINE xml_tab,xml_col om.domnode
DEFINE xml_cols om.nodelist

&define DBQ_REC \
		fld1 VARCHAR(max_col_len), \
		fld2 VARCHAR(max_col_len), \
		fld3 VARCHAR(max_col_len), \
		fld4 VARCHAR(max_col_len), \
		fld5 VARCHAR(max_col_len), \
		fld6 VARCHAR(max_col_len), \
		fld7 VARCHAR(max_col_len), \
		fld8 VARCHAR(max_col_len), \
		fld9 VARCHAR(max_col_len), \
		fld10 VARCHAR(max_col_len), \
		fld11 VARCHAR(max_col_len), \
		fld12 VARCHAR(max_col_len), \
		fld13 VARCHAR(max_col_len), \
		fld14 VARCHAR(max_col_len), \
		fld15 VARCHAR(max_col_len), \
		fld16 VARCHAR(max_col_len), \
		fld17 VARCHAR(max_col_len), \
		fld18 VARCHAR(max_col_len), \
		fld19 VARCHAR(max_col_len), \
		fld20 VARCHAR(max_col_len), \
		fld21 VARCHAR(max_col_len), \
		fld22 VARCHAR(max_col_len), \
		fld23 VARCHAR(max_col_len), \
		fld24 VARCHAR(max_col_len), \
		fld25 VARCHAR(max_col_len), \
		fld26 VARCHAR(max_col_len), \
		fld27 VARCHAR(max_col_len), \
		fld28 VARCHAR(max_col_len), \
		fld29 VARCHAR(max_col_len), \
		fld30 VARCHAR(max_col_len), \
		fld31 VARCHAR(max_col_len), \
		fld32 VARCHAR(max_col_len), \
		fld33 VARCHAR(max_col_len), \
		fld34 VARCHAR(max_col_len), \
		fld35 VARCHAR(max_col_len), \
		fld36 VARCHAR(max_col_len), \
		fld37 VARCHAR(max_col_len), \
		fld38 VARCHAR(max_col_len), \
		fld39 VARCHAR(max_col_len), \
		fld40 VARCHAR(max_col_len), \
		fld41 VARCHAR(max_col_len), \
		fld42 VARCHAR(max_col_len), \
		fld43 VARCHAR(max_col_len), \
		fld44 VARCHAR(max_col_len), \
		fld45 VARCHAR(max_col_len), \
		fld46 VARCHAR(max_col_len), \
		fld47 VARCHAR(max_col_len), \
		fld48 VARCHAR(max_col_len), \
		fld49 VARCHAR(max_col_len), \
		fld50 VARCHAR(max_col_len), \
		fld51 VARCHAR(max_col_len), \
		fld52 VARCHAR(max_col_len), \
		fld53 VARCHAR(max_col_len), \
		fld54 VARCHAR(max_col_len), \
		fld55 VARCHAR(max_col_len), \
		fld56 VARCHAR(max_col_len), \
		fld57 VARCHAR(max_col_len), \
		fld58 VARCHAR(max_col_len), \
		fld59 VARCHAR(max_col_len), \
		fld60 VARCHAR(max_col_len), \
		fld61 VARCHAR(max_col_len), \
		fld62 VARCHAR(max_col_len), \
		fld63 VARCHAR(max_col_len), \
		fld64 VARCHAR(max_col_len), \
		fld65 VARCHAR(max_col_len), \
		fld66 VARCHAR(max_col_len), \
		fld67 VARCHAR(max_col_len), \
		fld68 VARCHAR(max_col_len), \
		fld69 VARCHAR(max_col_len), \
		fld70 VARCHAR(max_col_len), \
		fld71 VARCHAR(max_col_len), \
		fld72 VARCHAR(max_col_len), \
		fld73 VARCHAR(max_col_len), \
		fld74 VARCHAR(max_col_len), \
		fld75 VARCHAR(max_col_len), \
		fld76 VARCHAR(max_col_len), \
		fld77 VARCHAR(max_col_len), \
		fld78 VARCHAR(max_col_len), \
		fld79 VARCHAR(max_col_len), \
		fld80 VARCHAR(max_col_len), \
		fld81 VARCHAR(max_col_len), \
		fld82 VARCHAR(max_col_len), \
		fld83 VARCHAR(max_col_len), \
		fld84 VARCHAR(max_col_len), \
		fld85 VARCHAR(max_col_len), \
		fld86 VARCHAR(max_col_len), \
		fld87 VARCHAR(max_col_len), \
		fld88 VARCHAR(max_col_len), \
		fld89 VARCHAR(max_col_len), \
		fld90 VARCHAR(max_col_len), \
		fld91 VARCHAR(max_col_len), \
		fld92 VARCHAR(max_col_len), \
		fld93 VARCHAR(max_col_len), \
		fld94 VARCHAR(max_col_len), \
		fld95 VARCHAR(max_col_len), \
		fld96 VARCHAR(max_col_len), \
		fld97 VARCHAR(max_col_len), \
		fld98 VARCHAR(max_col_len), \
		fld99 VARCHAR(max_col_len), \
		fld100 VARCHAR(max_col_len) 

&define ADDFLD(l,x,f,e,w) \
  LET lb = grid.createChild('Label') \
  CALL lb.setAttribute("text",l) \
  CALL lb.setAttribute("posX","1") \
  CALL lb.setAttribute("posY",x) \
  LET ff = grid.createChild('FormField') \
  CALL ff.setAttribute("colName",f) \
  LET edit = ff.createChild(e) \
  CALL edit.setAttribute("width",w) \
  CALL edit.setAttribute("posX","20") \
  CALL edit.setAttribute("posY",x)

