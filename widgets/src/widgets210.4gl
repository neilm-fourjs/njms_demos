&include "genero_lib1.inc"
	DEFINE x SMALLINT
	
	DEFINE arr1 DYNAMIC ARRAY OF RECORD
		fld1 CHAR(12),
		fld2 SMALLINT
	END RECORD

	DEFINE arr2 DYNAMIC ARRAY OF RECORD
		fld1 CHAR(12),
		fld2 SMALLINT
	END RECORD

	DEFINE rec RECORD
		fld1 SMALLINT,
		fld2 SMALLINT,
		sld1 SMALLINT,
		sld2 SMALLINT
	END RECORD
	
FUNCTION ndialog()
	DEFINE dir,dir1 SMALLINT
GL_MODULE_ERROR_HANDLER
	OPEN WINDOW md_win WITH FORM "md_form"

	FOR x = 1 TO 10
		LET arr1[x].fld1 = "Arr1 Row:"||x
		LET arr1[x].fld2 = 100+x
		LET arr2[x].fld1 = "Arr2 Row:"||x
		LET arr2[x].fld2 = 200+x
	END FOR

	DIALOG ATTRIBUTES(UNBUFFERED)
-- Binding
		DISPLAY ARRAY arr1 TO scr_arr1.*
			BEFORE ROW
				CALL md_disp("Before Row arr1:"||arr_curr())
				LET rec.fld1 = arr_curr()
				LET rec.sld1 = arr_curr()
			ON ACTION moveright
				LET arr2[arr2.getLength()+1].* = arr1[ DIALOG.getCurrentRow("scr_arr1") ].*
				CALL arr1.deleteElement( DIALOG.getCurrentRow("scr_arr1") )
		END DISPLAY
		DISPLAY ARRAY arr2 TO scr_arr2.*
			BEFORE ROW 
				CALL md_disp("Before Row arr2:"||arr_curr())
				LET rec.fld2 = arr_curr()
				LET rec.sld2 = arr_curr()
			ON ACTION moveleft
				LET arr1[arr1.getLength()+1].* = arr2[ DIALOG.getCurrentRow("scr_arr2") ].*
				CALL arr2.deleteElement( DIALOG.getCurrentRow("scr_arr2") )
		END DISPLAY
		INPUT BY NAME rec.*
			AFTER FIELD fld1
				CALL DIALOG.setCurrentRow("scr_arr1", rec.fld1 )

			AFTER FIELD fld2
				CALL DIALOG.setCurrentRow("scr_arr2", rec.fld2 )

			ON CHANGE sld1
				IF rec.sld1 < rec.fld1 THEN LET dir = 2 LET dir1 = -1 END IF
				IF rec.sld1 > rec.fld1 THEN LET dir = 1 LET dir1 = 0 END IF
				IF rec.fld1 + dir1 > 0 THEN
	--			DISPLAY "Inserting item:",rec.fld1,"@",rec.sld1 + dir, " dir:",dir," dir1:",dir1
	--			CALL md_disparr1()
				CALL arr1.insertElement( rec.sld1 + dir )
	--			CALL md_disparr1()
	--			DISPLAY "Assigning values to ",rec.sld1 + dir," of ",rec.fld1 + dir1," Elements:",arr1.getLength()
				LET arr1[rec.sld1 + dir].* = arr1[rec.fld1 + dir1].*
	--			CALL md_disparr1()
	--			DISPLAY "Removing original item:",rec.fld1 + dir1," of ",arr1.getLength()
				CALL arr1.deleteElement( rec.fld1 + dir1 )
	--			DISPLAY "Moving to new row:",rec.sld1," of ",arr1.getLength()
	--			CALL md_disparr1()
					CALL DIALOG.setCurrentRow("scr_arr1", rec.sld1 )
					LET rec.fld1 = rec.sld1
				END IF
			
		ON CHANGE sld2
				IF rec.sld2 < rec.fld2 THEN LET dir = 2 LET dir1 = -1 END IF
				IF rec.sld2 > rec.fld2 THEN LET dir = 1 LET dir1 = 0 END IF
				IF rec.fld2 + dir1 > 0 THEN
					CALL arr2.insertElement( rec.sld2 + dir )
					LET arr2[rec.sld2 + dir].* = arr2[rec.fld2 + dir1].*
					CALL arr2.deleteElement( rec.fld2 + dir1 )
					CALL DIALOG.setCurrentRow("scr_arr2", rec.sld2 )
					LET rec.fld2 = rec.sld2
				END IF
			
		END INPUT

-- Events
		BEFORE DIALOG
			CALL md_disp("Before Dialog")

		AFTER DIALOG
			CALL md_disp("Before Dialog")

-- Actions
		ON ACTION stat
			CALL md_disp( "Array 1 Row is "||DIALOG.getCurrentRow( "scr_arr1" )||" of "||DIALOG.getArrayLength("scr_arr1")||
									"\nArray 2 Row is "||DIALOG.getCurrentRow( "scr_arr2" )||" of "||DIALOG.getArrayLength("scr_arr2") )

		ON ACTION mycopy
			CALL mycopy( FGL_DIALOG_GETFIELDNAME(),DIALOG.getFieldBuffer( FGL_DIALOG_GETFIELDNAME() ) )

		ON ACTION move
			IF infield( fld1 ) THEN
				CALL DIALOG.setCurrentRow("scr_arr1", rec.fld1 )
			END IF
			IF infield( fld2 ) THEN
				CALL DIALOG.setCurrentRow("scr_arr2", rec.fld2 )
			END IF
			
		ON ACTION close
			EXIT DIALOG
		ON ACTION exit
			EXIT DIALOG
	END DIALOG

	MENU
		COMMAND "Exit"
			EXIT MENU
		ON ACTION close
			EXIT MENU
	END MENU

	CLOSE WINDOW md_win

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION md_disp( msg )
	DEFINE msg STRING
	
	MESSAGE msg
	DISPLAY msg
	DISPLAY msg TO statmsg

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION md_disparr1()
	DEFINE x SMALLINT
	
	DISPLAY "-------"
	FOR x = 1 TO arr1.getLength()
		IF arr1[x].fld1 IS NULL THEN LET arr1[x].fld1 = "NULL" END IF	
		DISPLAY x,":",arr1[x].fld1
	END FOR
	DISPLAY "-------"
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION mycopy( fldname, fldvalue )
	DEFINE fldname, fldvalue STRING

	DISPLAY "Fld:",fldname,"=",fldvalue

END FUNCTION