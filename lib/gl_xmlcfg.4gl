
&include "genero_lib1.inc"
--------------------------------------------------------------------------------
#+ XML Configuration file handling functions.
#+ $Id: gl_xmlcfg.4gl 309 2011-05-31 10:10:49Z  $
--------------------------------------------------------------------------------

#+ @param cfg  Xml node for the configuration.
#+ @param titl Title for the window
FUNCTION glCFG_OpenWindow(cfg, titl) --{{{
	DEFINE cfg om.domNode
	DEFINE titl STRING
	DEFINE w ui.Window
	DEFINE f ui.Form
	DEFINE p, h,v,g,n,n1 om.domNode
	DEFINE nl om.NodeList
	DEFINE txt STRING
	DEFINE x, y SMALLINT
GL_MODULE_ERROR_HANDLER
	OPEN WINDOW glcfg_win AT 1,1 WITH 10 ROWS, 40 COLUMNS ATTRIBUTES(STYLE="naked")
	LET w = ui.Window.getCurrent()
	LET f = w.createForm("mk_db_dbex")
	CALL w.setText( titl )
	LET g = f.getNode()
	LET v = g.createChild("VBox")
	LET g = v.createChild("Group")
	CALL g.setAttribute("width","40") CALL g.setAttribute("gridWidth","40")
	CALL g.setAttribute("text","Parameters")

	LET y = 1
	LET nl = cfg.selectByTagName("Param")
	FOR x = 1 TO nl.getLength()
		LET p = nl.item(x)
		LET txt = p.getAttribute("desc")
		IF p.getAttribute("type") = "String" THEN
			LET n1 = g.createChild("Label")
			CALL n1.setAttribute("width", txt.getLength() )
			CALL n1.setAttribute("gridWidth", txt.getLength() )
			CALL n1.setAttribute("text", txt )
			CALL n1.setAttribute("posX","0") 
			CALL n1.setAttribute("posY",y ) 
			LET n = g.createChild("FormField") 
			CALL n.setAttribute("colName",p.getAttribute("name") )
			CALL n.setAttribute("value", p.getAttribute("value") ) 
			LET n1 = n.createChild("Edit")
			CALL n1.setAttribute("width","20") 
			CALL n1.setAttribute("gridWidth","20")
			CALL n1.setAttribute("posX","20")
			CALL n1.setAttribute("posY",y ) 
		END IF
		IF p.getAttribute("type") = "Bool" THEN
			LET n = g.createChild("FormField") 
			CALL n.setAttribute("colName",p.getAttribute("name") )
			CALL n.setAttribute("notNull",1)
			CALL n.setAttribute("value", p.getAttribute("value") ) 
			LET n1 = n.createChild("CheckBox") 
			CALL n1.setAttribute("width", txt.getLength() + 3 )
			CALL n1.setAttribute("gridWidth", txt.getLength() + 3 )
			CALL n1.setAttribute("text", txt )
			CALL n1.setAttribute("posX","2") 
			CALL n1.setAttribute("posY",y)
		END IF
		IF p.getAttribute("type") = "Section" THEN
			LET n = g.createChild("HLine")
			CALL n.setAttribute("gridWidth","40")
			CALL n.setAttribute("posX","0")
			CALL n.setAttribute("posY",y)
			LET n = g.createChild("Label")
			CALL n.setAttribute("text", txt )
			CALL n.setAttribute("color","blue")
			CALL n.setAttribute("posX","5") 
			CALL n.setAttribute("posY",y)
		END IF
		LET y = y + 1
	END FOR

	LET n = g.createChild("HLine") CALL n.setAttribute("gridWidth","40")
	CALL n.setAttribute("posX","0") CALL n.setAttribute("posY",y)  LET y = y + 1

	LET n = g.createChild("Button") CALL n.setAttribute("name","accept")
	CALL n.setAttribute("posX","2") CALL n.setAttribute("posY",y) 
	CALL n.setAttribute("text","Process") CALL n.setAttribute("image","accept") 
	LET n = g.createChild("Button") CALL n.setAttribute("name","save")
	CALL n.setAttribute("posX","10") CALL n.setAttribute("posY",y)
	CALL n.setAttribute("text","Save Config") CALL n.setAttribute("image","save") 
	LET n = g.createChild("Button") CALL n.setAttribute("name","cancel")
	CALL n.setAttribute("posX","20") CALL n.setAttribute("posY",y)
	CALL n.setAttribute("text","Cancel") CALL n.setAttribute("image","cancel") 

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Close the window
FUNCTION glCFG_CloseWindow() --{{{

	CLOSE WINDOW glcfg_win

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Open the window
#+
#+ @param name Name of the file to read.
FUNCTION glCFG_Open( name ) --{{{
	DEFINE name STRING
	DEFINE xmlCfg om.domDocument
	DEFINE xmlCfg_n om.domNode
	
	LET xmlCfg = om.domDocument.createFromXmlFile( name||".xml" )
	IF xmlCfg IS NULL THEN
		RETURN NULL
--		LET xmlCfg = om.domDocument.create(name)
--		CALL glCFG_Create( xmlCfg.getDocumentElement() )
	END IF
	LET xmlCfg_n = xmlCfg.getDocumentElement()

	RETURN xmlCfg_n

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Create a new configuration file
#+
#+ @param name Name of configuration root node.
FUNCTION glCFG_Create( name ) --{{{
	DEFINE name STRING
	DEFINE xmlCfg om.domDocument
	DEFINE xmlCfg_n om.domNode

	LET xmlCfg = om.domDocument.create( name )
	LET xmlCfg_n = xmlCfg.getDocumentElement()

	RETURN xmlCfg_n
END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Save the config
#+
#+ @param name Name of the file to read.
FUNCTION glCFG_Save( r ) --{{{
	DEFINE r om.domNode
	DEFINE name STRING

	LET name = r.getTagName()

	CALL r.writeXML( name||".xml" )

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Create a new option
#+
#+ @param r Root node
#+ @param o Name attribute
#+ @param t Type attribute
#+ @param v Value attribute
#+ @param d Description attribute
FUNCTION glCFG_CreateOpt( r, o, t, v, d ) --{{{
	DEFINE r, n om.domNode
	DEFINE o, t, v, d STRING
	
	LET n = r.createChild("Param")
	CALL n.setAttribute("name", o)
	CALL n.setAttribute("type", t)
	CALL n.setAttribute("value", v)
	CALL n.setAttribute("desc", d)
	
END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Get an option from the config
#+
#+ @param r Root node
#+ @param o Name of option
#+ @return option value or null
FUNCTION glCFG_getOpt( r,o ) --{{{
	DEFINE r om.domNode
	DEFINE nl om.nodeList
	DEFINE o,v STRING

	LET nl = r.selectByPath("//Param[@name='"||o||"']")
	LET r = nl.item(1)
	IF r IS NOT NULL THEN
		LET v = r.getAttribute("value")
		IF v.getCharAt(1) = "$" THEN
			LET v = fgl_getEnv( v.subString(2, v.getLength() ) )
		END IF
		RETURN v
	END IF
	RETURN NULL

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Set the value of an option
#+
#+ @param r Root node
#+ @param o Name of option
#+ @param v New value
#+ @return true/false
FUNCTION glCFG_setOpt( r,o,v ) --{{{
	DEFINE r om.domNode
	DEFINE nl om.nodeList
	DEFINE o,v STRING

	LET nl = r.selectByPath("//Param[@name='"||o||"']")
	LET r = nl.item(1)
	IF r IS NULL THEN RETURN FALSE END IF

	CALL r.setAttribute("value",v)
	RETURN TRUE

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Get the description from the option
#+
#+ @param r Root node
#+ @param o Name of option
#+ @return description
FUNCTION glCFG_getDesc( r, o ) --{{{
	DEFINE r om.domNode
	DEFINE nl om.nodeList
	DEFINE o STRING

	LET nl = r.selectByPath("//Param[@name='"||o||"']")
	LET r = nl.item(1)
	IF r IS NOT NULL THEN
		RETURN r.getAttribute("desc")
	END IF
	RETURN NULL

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Set the description for the option
#+
#+ @param r Root node
#+ @param o Name of option
#+ @param v Description
FUNCTION glCFG_setDesc( r,o,v ) --{{{
	DEFINE r om.domNode
	DEFINE nl om.nodeList
	DEFINE o,v STRING

	LET nl = r.selectByPath("//Param[@name='"||o||"']")
	LET r = nl.item(1)
	IF r IS NULL THEN
		LET r = r.createChild(o)
	END IF
	IF r IS NOT NULL THEN
		CALL r.setAttribute("desc",v)
	END IF

END FUNCTION --}}}
--------------------------------------------------------------------------------
