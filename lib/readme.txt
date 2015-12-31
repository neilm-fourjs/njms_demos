
--------------------------------------------------------------------------------
-- Genero Library 1 - by Neil J Martin ( neilm@4js.com )
-- This library is intended as an example of useful library code for use with
-- Genero 1.33 & 2.00.
--
-- No warrantee of any kind, express or implied, is included with this software;
-- use at your own risk, responsibility for damages (if any) to anyone resulting
-- from the use of this software rests entirely with the user.
--------------------------------------------------------------------------------

Main Library Files:	
genero_lib1.4gl - Main source of library code
gl_lookup.4gl 	- A generic dynamic lookup function.

The rest of the files are makefiles and example source files for calling the library code.

Summary:

The Library Functions:	
gl_lookup:			A generic dynamic lookup.

gl_init:				Initialize Function
gl_formInit:		Form Initialize Function - called by auto initializer
gl_titleApp: 		Title the application ( name on start menu! )
gl_titleWin: 		Title current window ( eg: 2006/03/25: ProgName Ver - program Description )
gl_getWinNode:	Return the node for a named window - if null get current
gl_genForm:			Dynamically generate a form object & return it's node.
gl_getForm:			Return the form object for the named form - if null get current
gl_getFormN:		Return the form NODE for the named form - if null get current
gl_appendNode:	Append a node(+it's children) from a different DomDocument to a node.
gl_addPage:			Dynamically add a form as a page to the passed folder tab
gl_findPage:		Find a folder page.
gl_titlePage:		Dynamically change title of a page
gl_hidePage:		Dynamically hide/unhide a page
gl_showPage:		Dynamically change the current page in a folder
gl_hideToolBarItem: hides a toolbar item.
gl_findXmlCol:	Finds a column within a table in the xml schema.
gl_splash:			Splash screen
gl_about:				Dynamic About Window
gl_help:				Help Window
gl_prompt:			A Simple Prompt function
gl_winQuestion:	Generic Windows Button Dialog.
gl_progBar:			Progressbar Routine.
gl_defAction:		Dynamically define a live actions properties.
gl_setAttr: 		Set Attributes for a node.
gl_setProgMinMax: Set the min and max values for a progress bar.
gl_error:				Used by WHENEVER ERROR CALL gl_error in gl_init, it calls gl_errMsg()	
gl_errMsg:			Passed __FILE__,__LINE__,"Error Message" - gets displayed and log in logfile.
gl_chgArgs:     Change exec line of a start menu command ( use name="?" in the .4sm )
gl_popCombo: 		Populate the named combo box, if NULL clear combobox. if ASK! allow editting of vals
gl_addCombo: 		Populate the named combo box
gl_setElementStyle: Set the stlye attribute on an element of current form.
gl_dyntab:			Dynamically create a form with a table.
gl_genStrs: 		Generate a Strings file for use with localized strings.

NOTE: Some of these function call other functions included here, 
	eg gl_lookup use gl_progBar and gl_findXmlCol.


Details:
gl_init: Initialize Function
 	mdi_mdi 	= Char(1):	"S"-Sdi "M"-mdi Container "C"-mdi Child
		l_key 		= String:		name for .4ad/.4st/.4tb - default="mydefaults"
		l_use_fi 	= Smallint:	TRUE/FALSE Set Form Initializer to gl_forminit.
	RETURNS = Nothing.
--				CALL ui.interface.loadToolbar( m_key||".4tb" )
--			CALL ui.Interface.loadStartMenu( m_key||".4tb" )
--			CALL ui.Interface.loadToolbar("container")
--			CALL ui.interface.loadToolbar( m_key||".4tb" )
--------------------------------------------------------------------------------
gl_formInit: Form Initialize.
--------------------------------------------------------------------------------
gl_titleApp: title the application ( name on start menu! )
		titl	= String:	title for application
	RETURNS = none
--------------------------------------------------------------------------------
gl_getWinNode: Return the node for a named window.
		nam	= String:	name of window, if null current window node is returned.
	RETURNS = ui.Window.
--------------------------------------------------------------------------------
gl_genForm: Dynamically generate a form object & return it's node.
		nam	= String:	name of Form, Should not be NULL!
	RETURNS = ui.Form.
--------------------------------------------------------------------------------
gl_getForm: Return the form object for the named form.
		nam	= String:	name of Form, if null current Form object is returned.
	RETURNS = ui.Form.
--------------------------------------------------------------------------------
gl_getFormN: Return the form NODE for the named form.
		nam	= String:	name of Form, if null current Form node is returned.
	RETURNS = Node.
--------------------------------------------------------------------------------
gl_appendNode: Append a node(+it's children) from a different DomDocument to a node.
		cur	= Node:			node to append to
		new	= Node:			node to append from
		lv 	= Smallint:	0 - Used by this function for recursive calls.
	RETURNS = Nothing.
--------------------------------------------------------------------------------
gl_addPage: Dynamically add a form as a page to the passed folder tab
		fld		= Node:		node of Folder to add pages to.
		pgno 	= SmallInt:	number of the page, ie 1,2,3 etc
		fname = String:	name of the .42f to load ( without the extension )
		pgnam = String:	Title of the Page.
	RETURNS = Nothing.
--------------------------------------------------------------------------------
gl_findPage: Find a folder page.
		fld		= Node:		node of Folder to add pages to. Can be NULL
		fname = String:	name of the Folder ( if fld is NULL )
		page  = String:	name of the Page to find
	RETURNS = Node of page
	NOTE: fld or fname need to be supplied, both can't be NULL!
--------------------------------------------------------------------------------
gl_titlePage: Dynamically change title of a page
		folder = Node: Node of the folder, can be NULL
		fname  = String: Name of the folder, can be NULL only if folder is passed.
		page   = String: Name of the page to affected.
		title  = String: New title for the page.
	RETURNS = Nothing.
--------------------------------------------------------------------------------
gl_hidePage: Dynamically hide/unhide a page
		folder = Node: Node of the folder, can be NULL
		fname  = String: Name of the folder, can be NULL only if folder is passed.
		page   = String: Name of the page to hide/unhide
		hide   = Smallint: TRUE/FALSE = Hide/Unhide
	RETURNS = Nothing.
--------------------------------------------------------------------------------
gl_hidePage: Dynamically change the current page in a folder
		folder = Node: Node of the folder, can be NULL
		fname  = String: Name of the folder, can be NULL only if folder is passed.
		page   = String: Name of the page to set current.
 NOTE: looks more complicated than needed because it's making sure it only
 			effect pages that are visable.
	RETURNS = Nothing.
--------------------------------------------------------------------------------
gl_hideToolBarItem: hides a toolbar item.
		nam = String: Name of item
		hid = Boolean: TRUE/FALSE hide/unhide
	RETURNS = none
--------------------------------------------------------------------------------
gl_findXmlCol: Finds a column within a table in the xml schema.
		tabname	= String: Table name
		colname	= String: Colum name
		xml_sch	= Node: Your xml_schema
	RETURNS = Node.
--------------------------------------------------------------------------------
gl_chgComment: Dynamically change a comment(tooltip), for the named item.
		dia = Dialog: ui.dialog for the current dialog - can be NULL
		frm = Form:  ui.form for the current form - can be NULL - defaults to current
		nam = String: Name of form element to be affected.
		com = String: New comment value for the named element.
	RETURNS = Node.
--------------------------------------------------------------------------------
gl_splash: Splash screen
		PASSED Nothing.
		RETURNS = Nothing.
--	CALL n.setAttribute("posY",12)
--	CALL n.setAttribute("posX","0" )
--	CALL n.setAttribute("text",gl_progname||" - "||GL_VERSION||"(Build "||GL_BUILD||")")
--	LET n = g.createChild("Label")
--------------------------------------------------------------------------------
gl_about: Dynamic About Window
		PASSED Nothing.
		RETURNS = Nothing.
--	LET n = f.createChild("HBox")
--	CALL n.setAttribute("posY","20" )
--	CALL n.setAttribute("posX","2" )
--	LET g = n.createChild("Grid")
--------------------------------------------------------------------------------
gl_feVer: get FrontEnd type and Version String.
		PASSED NOTHING.
		RETURNS = String.
--------------------------------------------------------------------------------
		num = Smallint: No of help message to display.
		RETURNS = Nothing.
--------------------------------------------------------------------------------
gl_prompt: A Simple Prompt function 
	 	ex: LET tmp = prompt("A Simple Prompt","Enter a value","C",5,NULL)
	 	win_tit   = String: Window Title
	 	prmpt_txt = String: Label text
	 	prmpt_typ = Char(1): Data type for prompt C=char D=date
	 	prmpt_sz  = Smallint: Size of field for entry.
	 	prmpt_def = String: Default value ( can be NULL )
 	RETURNS = Char(50): Entered value.
--------------------------------------------------------------------------------
gl_winQuestion: Generic Windows Button Dialog.
	 	win_tit   = String: Window Title
	 	message   = String: Message text
	 	ans       = String: Default Answer
	 	items			= String: List of Answers ie "Yes|No|Cancel"
	 	icon      = String: Icon name, "exclamation"
 	RETURNS = Char(50): Entered value.
--------------------------------------------------------------------------------
gl_progBar: Progressbar Routine.
		Ex:
		 CALL gl_progBar(1,10,"Working...")   Open window and set max = 10
		 FOR x = 1 TO 10
			CALL gl_progBar(2,x,NULL)  Move the bar to x position
		 END FOR
		 CALL gl_progBar(3,0,NULL)   Close the window
		meth = Smallint: 1-Open Window / 2-Move bar / 3-Close Window
		curval = Smallint: if meth=1 :Max value for Bar.
		                   if meth=2 :Current value position for Bar.
		                   if meth=3 :Ignored.
		txt = String: Text display below the bar in the window.
 RETURNS = Nothing.
--------------------------------------------------------------------------------
gl_defAction: Dynamically define a live actions properties.
  	ex:BEFORE INPUT
		    CALL add_action("D","special","Special","A Special Action","wizard")
		typ = CHAR(1): D=dialog or M=MenuAction.
		nam = String: Name of Action.
		txt = String: Text for Action.
		com = String: Comment/Tooltip for Action.
		img = String: Image for Action.
 RETURNS = Nothing.
--------------------------------------------------------------------------------
gl_setProgMinMax: Set the min and max values for a progress bar.
		fld = String: tag property on the ProgressBar element.
		mn  = Integer: Min value
		mx  = Integer: Max value
	RETURNS = Nothing.
--------------------------------------------------------------------------------
gl_error: Default error handler
 PASSSED = Nothing.
	RETURNS = Nothing.
--------------------------------------------------------------------------------
gl_errMsg: Display an error message in a window, console & logfile.
		fil = String: __FILE__ - File name
		lne = Integer: __LINE__ - Line Number
		err = String: Error Message.
	RETURNS = Nothing.
--------------------------------------------------------------------------------
gl_popCombo: Populate the named combobox, 
		nam = String: The name of the combobox.
		val = String: The Value to add - NULL=clear combo ASK!=allow editting of values
		txt = String: Text value for the item.
 RETURNS = True / False: Worked / Failed
--------------------------------------------------------------------------------
gl_addCombo: Populate the named combo box - checks to see if item already exists.
 	cb = ComboBox: The Combobox object
		val = String: The value - ie return value for item.
		txt = String: The Text - ie display text for the item.
 RETURNS = True / False: Worked / Failed
--------------------------------------------------------------------------------
gl_setElementStyle: Set the stlye attribute on an element of current form.
		ele  = String: Elements name attribute.
		styl = String: Style to set.
 RETURNS = Nothing.
--------------------------------------------------------------------------------
gl_chgArgs: Change exec line of a start menu command ( use name="?" in the .4sm )
--------------------------------------------------------------------------------
gl_dyntab: A generic dynamic lookup table.
 Let key = dyntab( tabnam, tot_recs, colts, ftyp, flen )
 tabnam = table name - NOT DB Table!
 tot_recs = total number of records.
 colts = columns title up to MAX_COLS ( comma seperated )
					can be NULL to use column names
 ftyp  = types of columns D=Date, C=Char, N=Numeric/Decimal, I=Integer
					can be ?,?,? etc for default of column type from xml sch
 flen  = length of columns ( comma seperated )
					If NULL then defaults the sizes
--------------------------------------------------------------------------------





CHANGE LOG
Now sets int_flag = FALSE at start.
Now handles _ as column title to hide the column.
Now Jump Code should put new current row in the center of the list.








