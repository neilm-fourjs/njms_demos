
IMPORT os

	DEFINE max_images SMALLINT

	DEFINE pics DYNAMIC ARRAY OF RECORD
		pic STRING
	END RECORD
	DEFINE pics_info DYNAMIC ARRAY OF RECORD
		pth STRING,
		nam STRING,
		mod STRING,
		siz STRING,
		typ STRING,
		rwx STRING
	END RECORD
	DEFINE exts DYNAMIC ARRAY OF RECORD
		ext STRING,
		tf SMALLINT,
		desc STRING
	END RECORD
	DEFINE d,c INTEGER
	DEFINE m_base, path, html_start, html_end STRING
	DEFINE frm ui.Form
	DEFINE n om.domNode

MAIN

	DISPLAY "FGLSERVER:",fgl_getEnv("FGLSERVER")
	DISPLAY "FGLIMAGEPATH:",fgl_getEnv("FGLIMAGEPATH")
	DISPLAY "PWD:",os.path.pwd()

	OPEN FORM picf FROM "picflow"
	DISPLAY FORM picf

	LET max_images = 50

	LET exts[ exts.getLength() + 1].ext = "jpg" 
  LET exts[ exts.getLength() ].tf = TRUE LET exts[ exts.getLength() ].desc = "Compressed image"
	LET exts[ exts.getLength() + 1].ext = "png"
  LET exts[ exts.getLength() ].tf = TRUE LET exts[ exts.getLength() ].desc = "Portable Network Graphic"
	LET exts[ exts.getLength() + 1].ext = "gif"
  LET exts[ exts.getLength() ].tf = TRUE LET exts[ exts.getLength() ].desc = "Low Quality image"
	LET exts[ exts.getLength() + 1].ext = "bmp"
  LET exts[ exts.getLength() ].tf = TRUE LET exts[ exts.getLength() ].desc = "unCompressed image"
	LET exts[ exts.getLength() + 1].ext = "svg"
  LET exts[ exts.getLength() ].tf = TRUE LET exts[ exts.getLength() ].desc = "Scalable Vector Graphic - xml"

	LET m_base = ARG_VAL(1) 
	IF m_base IS NULL THEN 
		--LET m_base = ".."||os.path.separator()||".."||os.path.separator()||
		--	".."||os.path.separator()||"pics"||os.path.separator()
		LET m_base = FGL_GETENV("PICPATH")
	END IF
	DISPLAY "Base:"||m_base

--	CALL get_opts()

	CALL getImages("svg","png")

	DISPLAY "Image Found:",pics.getLength()

	LET html_start = "<P ALIGN=\"CENTER\">"
	LET html_end   = "<\P>"

	LET c = 1
	DIALOG ATTRIBUTE(UNBUFFERED)
		DISPLAY ARRAY pics TO pics.*
			BEFORE ROW
				LET c = arr_curr()
				CALL refresh( c )
--		ON IDLE 5
--			LET c = c + 1
--			IF c > pics.getLength() THEN LET c = 1 END IF
--			CALL DIALOG.setCurrentRow( "pics", c )
		END DISPLAY
	
		INPUT BY NAME c
			ON CHANGE c
				CALL DIALOG.setCurrentRow( "pics", c )
				CALL refresh( c )
		END INPUT

		BEFORE DIALOG
			LET frm = DIALOG.getForm()
			LET n = frm.findNode("FormField","formonly.c")
			LET n = n.getFirstChild()
			CALL n.setAttribute("valueMax", pics.getLength())

		ON ACTION quit EXIT DIALOG

		ON ACTION firstrow 
			LET c = 1
			CALL DIALOG.setCurrentRow( "pics", c )
			CALL refresh( c )
		ON ACTION lastrow 
			LET c = pics.getLength()
			CALL DIALOG.setCurrentRow( "pics", c )
			CALL refresh( c )
		ON ACTION nextrow 
			IF c < pics.getLength() THEN
				CALL DIALOG.setCurrentRow( "pics", ( c + 1 ) )
				CALL refresh( c + 1 )
			END IF
		ON ACTION prevrow 
			IF c > 1 THEN
				CALL DIALOG.setCurrentRow( "pics", ( c - 1 ) )
				CALL refresh( c - 1 )
			END IF

		ON ACTION close EXIT DIALOG
	END DIALOG

END MAIN
--------------------------------------------------------------------------------
FUNCTION refresh(l_c)
	DEFINE l_c SMALLINT
	LET c = l_c
	IF c < 1 THEN RETURN END IF
	DISPLAY html_start||pics_info[ c ].nam||html_end TO nam
	DISPLAY "Arr:",c,":",pics[ c ].pic
	DISPLAY c TO cur
	DISPLAY pics.getLength() TO max
	DISPLAY pics[ c ].pic TO img
	IF os.path.exists( pics[c].pic ) THEN
		DISPLAY "Found:",pics[c].pic
	ELSE
		DISPLAY "Not Found:",pics[c].pic
	END IF
	DISPLAY pics_info[ c ].nam TO d1
	DISPLAY pics_info[ c ].typ TO d2
	DISPLAY pics_info[ c ].pth TO d3
	DISPLAY pics_info[ c ].siz TO d4
	DISPLAY pics_info[ c ].mod TO d5
	DISPLAY pics_info[ c ].rwx TO d6
	
	CALL ui.interface.refresh()

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION chk_ext( ext )
	DEFINE ext STRING
	DEFINE x SMALLINT

	FOR x = 1 TO exts.getLength()
		IF ext = exts[x].ext AND exts[x].tf THEN RETURN TRUE END IF
	END FOR	
	RETURN FALSE
	
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION get_opts()

	OPEN WINDOW getopts WITH FORM "getopts"
	DIALOG ATTRIBUTES(UNBUFFERED)
		INPUT BY NAME m_base,max_images ATTRIBUTES(WITHOUT DEFAULTS=TRUE)
		END INPUT
		INPUT ARRAY exts FROM exts.* ATTRIBUTES(WITHOUT DEFAULTS=TRUE)
		END INPUT
		ON ACTION accept ACCEPT DIALOG
		ON ACTION cancel LET int_flag = TRUE EXIT DIALOG
		ON ACTION close LET int_flag = TRUE EXIT DIALOG
	END DIALOG
	CLOSE WINDOW getopts

	IF int_flag THEN EXIT PROGRAM END IF
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION getImages(p_ext,p_ext2)
	DEFINE p_ext,p_ext2, l_ext STRING

	CALL os.Path.dirSort( "name", 1 )
	LET d = os.Path.dirOpen( m_base )
	IF d > 0 THEN
		WHILE TRUE
			LET path = os.Path.dirNext( d )
			IF path IS NULL THEN EXIT WHILE END IF

			IF os.path.isDirectory( path ) THEN 
				--DISPLAY "Dir:",path
				CONTINUE WHILE 
			ELSE
				--DISPLAY "Fil:",path
			END IF

			LET l_ext = os.path.extension( path )
			IF l_ext IS NULL OR (p_ext != l_ext AND p_ext2 != l_ext) THEN CONTINUE WHILE END IF

			IF path.subString(1,6) = "banner" THEN CONTINUE WHILE END IF
			IF path.subString(1,6) = "FourJs" THEN CONTINUE WHILE END IF
			IF path.subString(1,6) = "Genero" THEN CONTINUE WHILE END IF
			IF path.subString(2,2) = "_" THEN CONTINUE WHILE END IF
			IF path.subString(3,3) = "_" THEN CONTINUE WHILE END IF
			IF path.subString(3,3) = "." THEN CONTINUE WHILE END IF

			LET pics[ pics.getLength() + 1 ].pic = path
			LET pics_info[ pics.getLength() ].nam = os.Path.rootName( path )
			LET pics_info[ pics.getLength() ].pth = m_base
			LET pics_info[ pics.getLength()].mod = os.Path.mtime( pics[ pics.getLength() ].pic )
			LET c = os.Path.size( m_base||path )
			LET pics_info[ pics.getLength()].siz = c USING "<<,<<<,<<<"
			LET pics_info[ pics.getLength()].pth = m_base
			LET pics_info[ pics.getLength()].typ = l_ext
			LET pics_info[ pics.getLength()].rwx = os.Path.rwx( m_base||path )
			--DISPLAY pics.getLength(),": File:",path," Ext:",l_ext
			IF pics.getLength() = max_images THEN EXIT WHILE END IF
		END WHILE
	END IF

END FUNCTION
--------------------------------------------------------------------------------