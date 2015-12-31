
#+ File Handling
#+ $Id: gl_fileUtils.4gl 344 2015-08-18 11:23:17Z neilm $

&ifdef genero13x
&else
IMPORT os
&endif

&include "genero_lib1.inc"

DEFINE namarr DYNAMIC ARRAY OF RECORD
		icon STRING,
		name STRING,
		type STRING,
		size STRING,
		mdte STRING
	END RECORD

&ifdef genero13x
&include "fileutil.inc"
&endif

--------------------------------------------------------------------------------
#+
FUNCTION gl_fileOpen(dirname,filt_typnam,filt_typ,titl) --{{{
	DEFINE dirname STRING
	DEFINE filt_typnam STRING
	DEFINE filt_typ STRING
	DEFINE titl STRING
	DEFINE prevdir STRING
	DEFINE startdir STRING
	DEFINE fname STRING
	DEFINE cb ui.comboBox
GL_MODULE_ERROR_HANDLER
&ifdef genero13x
	CALL fgl_winMessage("Sorry","Not Available in 1.33!","exclamation")
	RETURN NULL
&endif

	--OPEN FORM openfile FROM "form"
	--DISPLAY FORM openfile
	OPEN WINDOW openfile WITH FORM "gl_fileUtils"
	
	LET cb = ui.comboBox.forName( "ftype" )
	CALL cb.addItem(filt_typnam,filt_typnam)
	
	CALL fgl_setTitle(titl)
	
	DISPLAY filt_typnam TO ftype

--	INPUT BY NAME 
	LET startdir = fgl_file_pwd()
	
	LET int_flag = FALSE
	WHILE NOT int_flag
		CALL namarr.clear()
		IF NOT fgl_file_chdir( dirname ) THEN
			CALL fgl_winMessage("Error","Failed to chdir to '"||startdir||"'!","exclamation")
		END IF
--		DISPLAY "pwd:",fgl_file_pwd()
		LET dirname = fgl_file_pwd()
		CALL gl_readDir(dirname,filt_typ)
--		DISPLAY "Dirname:",dirname	
		DISPLAY ARRAY namarr TO arr.* ATTRIBUTES( COUNT=namarr.getLength() )
			BEFORE DISPLAY
				DISPLAY dirname TO dirname
				IF prevdir IS NULL THEN CALL DIALOG.setActionActive("back",FALSE) END IF
				IF dirname = "/" THEN CALL DIALOG.setActionActive("uplv",FALSE) END IF
			BEFORE ROW
				IF namarr[ arr_curr() ].type != "Directory" THEN
					DISPLAY namarr[ arr_curr() ].name TO fname
				END IF
			ON ACTION back 
				LET dirname = prevdir
				EXIT DISPLAY
			ON ACTION uplv
				LET prevdir = dirname
				LET dirname = ".."
				EXIT DISPLAY
			ON ACTION accept
				IF namarr[ arr_curr() ].type = "Directory" THEN
					LET prevdir = dirname
					LET dirname = namarr[ arr_curr() ].name.trim()
					EXIT DISPLAY
				ELSE
					LET fname = namarr[ arr_curr() ].name.trim()
					EXIT DISPLAY
				END IF
		END DISPLAY
		IF fname IS NOT NULL THEN EXIT WHILE END IF
	END WHILE
	
	CLOSE WINDOW openfile
	
	IF NOT fgl_file_chdir( startdir ) THEN
		CALL fgl_winMessage("Error","Failed to return to '"||startdir||"'!","exclamation")
	END IF
	LET int_flag = FALSE
	RETURN fname

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Read the directory.
FUNCTION gl_readDir(path,filt_typ) --{{{
	DEFINE path,typ STRING
	DEFINE filt_typ STRING
	DEFINE child STRING
	DEFINE h,size INTEGER
	IF NOT fgl_file_exists(path) THEN
--		DISPLAY "Path:",path," Doesn't Exist"
		RETURN
	END IF
	IF NOT fgl_file_isdirectory(path) THEN
--		DISPLAY "File:",fgl_file_basename(path)
		RETURN
	END IF
	LET h = fgl_file_diropen(path)
	WHILE h > 0
		 LET child = fgl_file_dirnext(h)
		 IF child IS NULL THEN EXIT WHILE END IF
			IF filt_typ IS NOT NULL AND fgl_file_type( child ) = "file" THEN
				IF NOT child MATCHES filt_typ THEN CONTINUE WHILE END IF
			END IF
			LET namarr[ namarr.getLength() + 1 ].name = child
			LET namarr[ namarr.getLength() ].mdte = fgl_file_mtime( child )
			CASE fgl_file_type( child ) 
				WHEN "file"
					LET namarr[ namarr.getLength() ].icon = "file"
					LET size = fgl_file_size( child )
					IF size > 0 AND size < 1024 THEN LET size = 1024 END IF
					LET namarr[ namarr.getLength() ].size = (size / 1024) USING "#,###,##&k"
					LET typ = gl_getFileType( child )
				WHEN "directory"
					LET namarr[ namarr.getLength() ].icon = "folder"
					LET typ = "Directory"
			END CASE
			LET namarr[ namarr.getLength() ].type = typ
	END WHILE
	CALL fgl_file_dirclose(h)
END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Return the file type description for the given name
#+
#+ @param file Filename
#+ @return Description String
FUNCTION gl_getFileType( file ) --{{{
	DEFINE file STRING

	CASE fgl_file_extension( file )
		WHEN "4gl" RETURN "4gl Form Source"
		WHEN "per" RETURN "4gl Screen"
		WHEN "str" RETURN "4gl Strings"
		WHEN "42m" RETURN "Obj Module"
		WHEN "42r" RETURN "Obj Runable"
		WHEN "42x" RETURN "Obj Library"
		WHEN "42f" RETURN "Obj Form"
		WHEN "42s" RETURN "Obj Strings"
		WHEN "4st" RETURN "Style File"
		WHEN "4tb" RETURN "Toolbar"
		WHEN "4tm" RETURN "TopMenu"
		WHEN "4sm" RETURN "StartMenu"
		WHEN "4ad" RETURN "Action Defaults"
		WHEN "sch" RETURN "Schema"
		WHEN "png" RETURN "Image Png"
		WHEN "jpg" RETURN "Image Jpg"
		WHEN "jpeg" RETURN "Image Jpeg"
		WHEN "bmp" RETURN "Image bmp"
		WHEN "gif" RETURN "Image gif"
		OTHERWISE
			RETURN fgl_file_extension( file.toUpperCase() ) 
	END CASE
END FUNCTION --}}}
