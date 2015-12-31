
IMPORT os

GLOBALS
	DEFINE langs DYNAMIC ARRAY OF RECORD
		nam CHAR(12),
		lang CHAR(12),
		img CHAR(2)
	END RECORD
	
	DEFINE rec RECORD
			lang CHAR(12),
			c_text CHAR(30),
			c_comm CHAR(160),
			c_text_t CHAR(60),
			c_comm_t CHAR(160),
			c_image CHAR(20),
			c_acc1 CHAR(20),
			c_acc2 CHAR(20)
	END RECORD
	
	DEFINE a_rec DYNAMIC ARRAY OF RECORD
			lang CHAR(12),
			c_text CHAR(30),
			c_comm CHAR(160),
			c_text_t CHAR(60),
			c_comm_t CHAR(160),
			c_image CHAR(20),
			c_acc1 CHAR(20),
			c_acc2 CHAR(20)
	END RECORD

	DEFINE imgs DYNAMIC ARRAY OF RECORD
		img STRING,
		nam STRING
	END RECORD

	DEFINE m_path STRING
	DEFINE stmt CHAR(200)

END GLOBALS

DEFINE cur_row SMALLINT
DEFINE dbnam VARCHAR(20)
DEFINE db VARCHAR(150)
DEFINE dsn, dbdrv STRING
DEFINE envlang, envlocale STRING

MAIN
	DEFINE x SMALLINT
	DEFINE l_mode, l_file STRING

	CALL gldb_connect(NULL)
	DISPLAY "FGLPROFILE=",fgl_getEnv("FGLPROFILE")
	DISPLAY "FGLIMAGEPATH=",fgl_getEnv("FGLIMAGEPATH")

	LET envlang = fgl_getEnv("LANG")
	IF envlang IS NULL THEN LET envlang = "(null)" END IF
	LET envlocale = fgl_getEnv("LOCALE")
	IF envlocale IS NULL THEN LET envlocale = "(null)" END IF

	LET l_mode = ARG_VAL(1)
	IF l_mode = "CREATE" THEN
		CALL cre_db()
		LET l_mode = "INIT"
	END IF
	
	LET cur_row = 1
	LET m_path = "../unicode/etc/"

	TRY
		SELECT COUNT(*) FROM uc_langs
	CATCH
		LET l_mode = "INIT"
	END TRY

	IF l_mode = "INIT" THEN
		CALL cre()
		LET l_file = base.application.getprogramdir()||os.path.separator()||m_path||os.path.separator()||"uc_labels.unl"
		TRY
			LOAD FROM l_file INSERT INTO uc_labels 
		CATCH
			DISPLAY "Failed to open '"||l_file||"' error="||ERR_GET( STATUS )
			EXIT PROGRAM
		END TRY
		CALL genstr()
		DISPLAY "Finished Init DB."
	END IF

	CALL ui.interface.loadActionDefaults("default")

--	LET stmt = "SELECT COUNT(*) FROM systables -- test"
--	PREPARE pre_test FROM stmt
--	EXECUTE pre_test

	DECLARE cur CURSOR FOR SELECT * FROM uc_langs
	LET x = 1
	FOREACH cur INTO langs[x].*
		LET x = x + 1
	END FOREACH
	CALL langs.deleteElemeNt(x)
	DISPLAY langs.getLength()," Languages."

	CALL loadpics()

	OPEN FORM test FROM "f_unicode"
	DISPLAY FORM test
	CALL fgl_setTitle("Unicode Demo - LANG="||envlang||" LOCALE="||envlocale )

	LET rec.lang = envlang
	FOR x = 1 TO langs.getLength()
		IF rec.lang = langs[x].lang THEN EXIT FOR END IF
	END FOR
	IF x > langs.getLength() THEN LET x = 1 END IF

	CALL sel()	
	DISPLAY BY NAME langs[x].img
	CALL dsp()	
	IF int_flag THEN EXIT PROGRAM END IF

	EXIT PROGRAM
-- Not using this menu any more!

	MENU 
		ON ACTION lang
			CALL inp()
		ON ACTION update
			CALL lst(TRUE)
		ON ACTION add
			LET rec.c_text = NULL
			CALL lst(TRUE)
		ON ACTION list
			CALL lst(FALSE)
		ON ACTION unload
			UNLOAD TO "uc_labels.unl" SELECT * FROM uc_labels ORDER BY c_text
		ON ACTION load
			DELETE FROM uc_labels
			LOAD FROM "uc_labels.unl" INSERT INTO uc_labels
--		ON ACTION cre
--			CALL cre()
		ON ACTION genstr
			CALL genstr()
		ON ACTION exit
			EXIT MENU
	END MENU

END MAIN
--------------------------------------------------------------------------------
FUNCTION inp()
	DEFINE img CHAR(2)

	LET int_flag = FALSE
	INPUT BY NAME rec.lang WITHOUT DEFAULTS
		ON CHANGE lang
			LET img = DOWNSHIFT( rec.lang[4,5] )
			DISPLAY "IMG:",img," lang:",rec.lang
			DISPLAY BY NAME img
			CALL sel()
			EXIT INPUT
	END INPUT

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION add()

	LET int_flag = FALSE
	INPUT BY NAME rec.* WITHOUT DEFAULTS ATTRIBUTES(UNBUFFERED)
	
	IF NOT int_flag THEN
		INSERT INTO uc_labels VALUES(rec.*)
	END IF

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION get_langnam( lang )
	DEFINE lang CHAR(12)
	DEFINE x SMALLINT

	FOR x = 1 TO langs.getLength()
		IF lang = langs[x].lang THEN RETURN langs[x].nam END IF
	END FOR

	RETURN NULL

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION sel()
	DEFINE x SMALLINT

	DECLARE sel_cur CURSOR FOR SELECT * FROM uc_labels WHERE lang = rec.lang
	LET x = 0
	CALL a_rec.clear()
	FOREACH sel_cur INTO rec.*
		LET x = x + 1
		LET a_rec[x].* = rec.*
		DISPLAY a_rec[x].c_text,":",a_rec[x].c_text_t
	END FOREACH
	DISPLAY "Select:",STATUS," rows:",a_rec.getLength()," cur_row:",cur_row
	LET rec.* = a_rec[cur_row].*

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION dsp()

	DISPLAY BY NAME rec.*

	LET int_flag = FALSE
	WHILE NOT int_flag
		DISPLAY ARRAY a_rec TO a_scr.* ATTRIBUTE( COUNT=a_rec.getLength(), UNBUFFERED )
			BEFORE ROW
				LET cur_row = arr_curr()
				LET rec.* = a_rec[cur_row].*
				DISPLAY BY NAME rec.*
			ON ACTION lang
				CALL inp()
				LET int_flag = FALSE
			ON ACTION list
				LET rec.* = a_rec[ arr_curr() ].*
				CALL lst(FALSE)
				LET int_flag = FALSE
			ON ACTION update
				LET rec.* = a_rec[ arr_curr() ].*
				CALL lst(TRUE)
				LET int_flag = FALSE
			ON ACTION add
				INITIALIZE rec.* TO NULL
				CALL lst(TRUE)
				LET int_flag = FALSE
			ON ACTION unload
				UNLOAD TO "uc_labels.unl" SELECT * FROM uc_labels ORDER BY c_text
			ON ACTION exit
				LET int_flag = TRUE
				EXIT DISPLAY
		END DISPLAY
	END WHILE
	
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION lst(add)
	DEFINE add SMALLINT
	DEFINE a_lst DYNAMIC ARRAY OF RECORD
		img CHAR(2),
		lang CHAR(12),
		c_text_t CHAR(60),
		c_comm_t CHAR(160)
	END RECORD
	DEFINE x,ins SMALLINT
	
	LET ins = FALSE
	IF rec.c_text IS NULL THEN LET ins = TRUE END IF
	OPEN WINDOW lst WITH FORM "f_unicode2"
	CALL loadkeys()
	
	CALL a_lst.clear()
	FOR x = 1 TO langs.getLength()
		LET a_lst[x].img = langs[x].img
		LET a_lst[x].lang = langs[x].lang
		LET a_lst[x].c_text_t = NULL
		LET a_lst[x].c_comm_t = NULL
		SELECT c_text_t, c_comm_t INTO a_lst[x].c_text_t, a_lst[x].c_comm_t
			FROM uc_labels WHERE c_text = rec.c_text
			 AND lang = langs[x].lang
		DISPLAY "lang:",a_lst[x].lang," text_t:",a_lst[x].c_text_t," Stat:",STATUS
	END FOR
	DISPLAY BY NAME rec.c_text,rec.c_comm,rec.c_image,rec.c_acc1,rec.c_acc2
	
	IF add THEN
		LET int_flag = FALSE
		DIALOG ATTRIBUTES(UNBUFFERED)
			INPUT BY NAME rec.c_text,rec.c_comm,rec.c_image,rec.c_acc1,rec.c_acc2 ATTRIBUTES(WITHOUT DEFAULTS=TRUE)
				ON ACTION imglist
					LET rec.c_image = lookimg()
				AFTER INPUT
					IF ins THEN
						FOR x = 1 TO langs.getLength()
							LET a_lst[x].c_text_t = rec.c_text
							LET a_lst[x].c_comm_t = rec.c_comm
						END FOR
					ELSE
						LET a_lst[1].c_comm_t = rec.c_comm
					END IF
			END INPUT
			INPUT ARRAY a_lst FROM a_lst.* ATTRIBUTES(INSERT ROW=FALSE, APPEND ROW=FALSE, DELETE ROW=FALSE )
				--BEFORE ROW
					--LET rec.
				ON ACTION accept
					IF a_lst[1].c_text_t IS NOT NULL THEN
						FOR x = 1 TO langs.getLength()
							LET rec.lang = langs[x].lang
							LET rec.c_text_t = a_lst[x].c_text_t
							LET rec.c_comm_t = a_lst[x].c_comm_t
							IF rec.c_text_t IS NOT NULL THEN
								DELETE FROM uc_labels WHERE lang = rec.lang AND c_text = rec.c_text
								INSERT INTO uc_labels VALUES( rec.* )
								DISPLAY "Inserting:",rec.lang,":",rec.c_text_t,": STATUS:",STATUS
							END IF
						END FOR
					END IF
			END INPUT
			ON ACTION close EXIT DIALOG
		END DIALOG
	ELSE
		LET int_flag = FALSE
		DISPLAY ARRAY a_lst TO a_lst.* ATTRIBUTE( COUNT=a_lst.getLength() )
	END IF

	CLOSE WINDOW lst

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION cre()
	DEFINE cre CHAR(1000)
	DEFINE x SMALLINT

	WHENEVER ERROR CONTINUE
	DROP TABLE uc_labels
	DROP TABLE uc_langs
	DISPLAY "DROP:",STATUS
	WHENEVER ERROR STOP

	LET cre = "CREATE TABLE uc_labels (",
		"lang CHAR(12),",
		"c_text CHAR(30),",
		"c_comm CHAR(80),",
&ifdef NCHAR
		"c_text_t NCHAR(60),",
		"c_comm_t NCHAR(160),",
&else
		"c_text_t CHAR(60),",
		"c_comm_t CHAR(160),",
&endif
		"c_image CHAR(20),",
		"c_acc1 CHAR(20),",
		"c_acc2 CHAR(20)",
	")"
	DISPLAY "Pre:",cre CLIPPED
	PREPARE pre FROM cre
	EXECUTE pre
	DISPLAY "CREATE:",STATUS

	LET cre = "CREATE TABLE uc_langs (",
		"lang CHAR(12),",
		"nam  CHAR(12),",
		"img  CHAR(2)",
	")"
	DISPLAY "Pre:",cre CLIPPED
	PREPARE pre2 FROM cre
	EXECUTE pre2
	DISPLAY "CREATE:",STATUS

	LET langs[langs.getLength() + 1].nam = "english"    LET langs[langs.getLength()].lang = "en_GB.UTF-8" 
	LET langs[langs.getLength() + 1].nam = "french"     LET langs[langs.getLength()].lang = "fr_FR.UTF-8" 
	LET langs[langs.getLength() + 1].nam = "german"     LET langs[langs.getLength()].lang = "de_DE.UTF-8" 
	LET langs[langs.getLength() + 1].nam = "danish"     LET langs[langs.getLength()].lang = "da_DK.UTF-8" 
	LET langs[langs.getLength() + 1].nam = "swedish"    LET langs[langs.getLength()].lang = "sv_SE.UTF-8" 
	LET langs[langs.getLength() + 1].nam = "spanish"    LET langs[langs.getLength()].lang = "es_ES.UTF-8" 
	LET langs[langs.getLength() + 1].nam = "portuguese" LET langs[langs.getLength()].lang = "pt_PT.UTF-8" 
	LET langs[langs.getLength() + 1].nam = "russian"    LET langs[langs.getLength()].lang = "ru_RU.UTF-8"
	LET langs[langs.getLength() + 1].nam = "chinese"    LET langs[langs.getLength()].lang = "zh_CN.UTF-8" 
	LET langs[langs.getLength() + 1].nam = "korean"     LET langs[langs.getLength()].lang = "ko_KR.UTF-8"  
	LET langs[langs.getLength() + 1].nam = "greek"      LET langs[langs.getLength()].lang = "el_GR.UTF-8"
	LET langs[langs.getLength() + 1].nam = "japanese"   LET langs[langs.getLength()].lang = "ja_JP.UTF-8"
	LET langs[langs.getLength() + 1].nam = "arabic"     LET langs[langs.getLength()].lang = "ar_AE.UTF-8"

	DISPLAY "Inserting:",langs.getLength()
	FOR x = 1 TO langs.getLength()
		LET langs[x].img = DOWNSHIFT( langs[x].lang[4,5] )
		INSERT INTO uc_langs VALUES(langs[x].*)

--		CALL set_rec1( langs[x].lang, langs[x].nam ) -- Example 1
--		INSERT INTO uc_labels VALUES(rec.*)
--		DISPLAY "Insert:",STATUS

--		CALL set_rec2( langs[x].lang, langs[x].nam ) -- Example 2
--		INSERT INTO uc_labels VALUES(rec.*)
--		DISPLAY "Insert:",STATUS
	END FOR
	SELECT COUNT(*) INTO x FROM uc_labels
	MESSAGE "Inserted:",x

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION genstr()
	DEFINE chl base.channel
	DEFINE x,y SMALLINT
	DEFINE str,trn CHAR(60)

	LET chl = base.channel.create()
	
	FOR x = 1 TO langs.getLength()
-- Write the strings file.
		TRY
			CALL chl.openFile(m_path||langs[x].nam CLIPPED||".str","w")
		CATCH
			DISPLAY "Failed to open:",m_path||langs[x].nam CLIPPED||".str"
			EXIT PROGRAM
		END TRY
		DISPLAY "Creating:",langs[x].nam CLIPPED," Strings..."
		LET rec.lang = langs[x].lang
		CALL sel()
		FOR y = 1 TO a_rec.getLength()	
			LET str = a_rec[y].c_text
			LET trn = a_rec[y].c_text_t
			CALL chl.writeLine("\""||str CLIPPED||"\"=\""||trn CLIPPED||"\"")
		END FOR
		CALL chl.close()
		RUN "cd etc;fglmkstr "||langs[x].nam CLIPPED

-- Write the env file
		CALL chl.openFile( "env."||langs[x].img CLIPPED,"w" )
		CALL chl.writeLine("export FGLPROFILE=$HOME/all/demos/unicode/etc/profile."||langs[x].img CLIPPED)
		CALL chl.writeLine("export LOCALE="||langs[x].lang)
		CALL chl.writeLine("export LANG="||langs[x].lang)
		CALL chl.writeLine("export MAKELANG=1")
		CALL chl.writeLine("")
		CALL chl.writeLine("source ./env")
		CALL chl.close()

-- Write the profile
		CALL chl.openFile( m_path||"profile."||langs[x].img CLIPPED,"w" )
		CALL chl.writeLine("fglrun.localization.file.count = 1")
		CALL chl.writeLine("fglrun.localization.file.1.name = \""||langs[x].nam CLIPPED||"\"")
		CALL chl.writeLine("")
		CALL chl.writeLine("# GeneroDB")
		CALL chl.writeLine("#dbi.default.driver = \"dbmads380\"")
		CALL chl.writeLine("")
		CALL chl.writeLine("# Informix")
		CALL chl.writeLine("dbi.default.driver = \"dbmifx9x\"")
		CALL chl.writeLine("")
		CALL chl.writeLine("# SQL Server")
		CALL chl.writeLine("#dbi.default.driver = \"dbmmsv80\"")
		CALL chl.close()
	END FOR

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION popcombo(cb)	
	DEFINE cb ui.combobox
	DEFINE x SMALLINT

	FOR x = 1 TO langs.getLength()
		CALL cb.addItem( langs[x].lang CLIPPED, langs[x].nam CLIPPED||" ("||langs[x].lang||")" )
	END FOR

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION loadpics()
	DEFINE ch_pic base.channel
	DEFINE line, file STRING

	LET ch_pic = base.Channel.create()
	LET file = base.application.getprogramdir()||os.path.separator()||m_path||os.path.separator()||"pics.unl"
	TRY
	CALL ch_pic.openfile( file,"r" )
	CATCH
		DISPLAY "Failed to open '"||file||"' error="||ERR_GET( STATUS )
		EXIT PROGRAM
	END TRY

	LET line = ch_pic.readline()
	WHILE line IS NOT NULL
		LET imgs[ imgs.getLength() + 1].img = line.trimright()
		LET imgs[ imgs.getLength()].nam = line.trim()
		LET line = ch_pic.readline()
	END WHILE
	CALL ch_pic.close()
	
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION loadkeys()
	DEFINE ch_key base.channel
	DEFINE cb1 ui.ComboBox
	DEFINE cb2 ui.ComboBox
--	DEFINE cb3 ui.ComboBox
	DEFINE line STRING

	LET cb1 = ui.ComboBox.forName("c_acc1")
	LET cb2 = ui.ComboBox.forName("c_acc2")
--	LET cb3 = ui.ComboBox.forName("acc3")

	LET ch_key = base.Channel.create()
	CALL ch_key.openfile( "../etc/keys.unl","r" )
	IF STATUS != 0 THEN
		DISPLAY "Failed to open keys.unl"
		EXIT PROGRAM
	END IF
	LET line = ch_key.readline()
	WHILE line IS NOT NULL
--		DISPLAY line
		CALL cb1.addItem(line.trim(),line.trim())
		CALL cb2.addItem(line.trim(),line.trim())
--		CALL cb3.addItem(line.trim(),line.trim())
		LET line = ch_key.readline()
	END WHILE
	CALL ch_key.close()
	
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION lookimg()

	OPEN WINDOW lookup WITH FORM "lookup"
	DISPLAY ARRAY imgs TO itms.* ATTRIBUTE( COUNT=imgs.getlength() )
	CLOSE WINDOW lookup
	IF NOT int_flag THEN
		RETURN imgs[ arr_curr() ].nam
	ELSE
		RETURN ""
	END IF

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION cre_db()
	DEFINE quot CHAR(1)
	DEFINE usr STRING
	DEFINE stat SMALLINT

	LET quot = "  "
	
	LET db = "db_ads+driver='dbmads380',source='"||dsn||"',username='SYSTEM',password='SYSTEM',resource='spec'"

	DISPLAY 'dB:',db CLIPPED
	DATABASE db
	LET stat = STATUS
	DISPLAY "Connected:",stat,":",SQLERRMESSAGE
	IF stat != 0 THEN
		EXIT PROGRAM
	END IF

	LET usr = dbnam
	LET usr = quot||usr.trim()||quot
	DISPLAY 'Creating Schema:',usr

	CALL do_it('DROP USER '||usr)
	CALL do_it('CREATE USER '||usr||' IDENTIFIED BY '||usr)
	CALL do_it('GRANT CREATE TABLE TO '||usr)
	CALL do_it('GRANT CONNECT TO '||usr)

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION do_it( stmt )
	DEFINE stmt VARCHAR(500)

	DISPLAY "Stmt:",stmt CLIPPED

	LET STATUS=0
	TRY
		PREPARE pre1 FROM stmt
	CATCH
		DISPLAY "Prepare:",SQLERRMESSAGE
		RETURN
	END TRY

	TRY
		EXECUTE pre1
	CATCH
		DISPLAY "Execute:",SQLERRMESSAGE
		RETURN
	END TRY
	DISPLAY "Done."

END FUNCTION
