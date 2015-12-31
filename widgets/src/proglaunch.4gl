
{ CVS Header
$Author: $
$Date: 2008-07-22 18:00:16 +0100 (Tue, 22 Jul 2008) $
$Revision: 2 $
$Source: /usr/home/test4j/cvs/all/demos/widgets/src/proglaunch.4gl,v $
$Log: proglaunch.4gl,v $
Revision 1.7  2007/07/12 16:43:03  test4j
*** empty log message ***

Revision 1.6  2006/07/21 11:23:08  test4j
*** empty log message ***

Revision 1.1  2005/11/17 18:14:12  test4j
*** empty log message ***

Revision 1.4  2005/11/16 13:24:30  test4j
*** empty log message ***

Revision 1.3  2005/05/10 14:48:12  test4j

Added cvs header.

}

DEFINE buffer RECORD
	Buff1 CHAR(128),
	Buff2 CHAR(128),
	Buff3 INTEGER
END RECORD

DEFINE ret SMALLINT
DEFINE dir_tree ARRAY[50] OF CHAR(30)
DEFINE dir_name ARRAY[500] OF CHAR(200)
DEFINE mod_name ARRAY[1000] OF CHAR(30)
DEFINE prg_name ARRAY[500] OF CHAR(30)
DEFINE tre_cnt SMALLINT
DEFINE dir_cnt SMALLINT
DEFINE mod_cnt SMALLINT
DEFINE prg_cnt SMALLINT

DEFINE cnl1 base.channel

DEFINE dos SMALLINT
DEFINE debug SMALLINT

DEFINE cmd CHAR(220)
DEFINE newcmd CHAR(220)
DEFINE cwd CHAR(120)
DEFINE sla CHAR(1) -- Slash
DEFINE cs CHAR(1) -- Command seperator
DEFINE editfile CHAR(60)

FUNCTION prog_launch()

	WHENEVER ERROR CONTINUE

	LET tre_cnt = 1
	LET dir_tree[tre_cnt] = "."

	LET cwd = ".."
	LET sla = "/"
	LET cs = ";"


	LET debug = FALSE
	IF base.application.getArgument(1) = "-d" THEN
		LET debug = TRUE
		DISPLAY "Debug ON"
		DISPLAY "getProgramName: '", base.application.getProgramName(),"'"
		DISPLAY "getFgldir: '", base.application.getFglDir(),"'"
		IF base.application.getProgramDir() IS NULL THEN
			DISPLAY "getProgramDir: NULL"
		ELSE
			DISPLAY "getProgramDir: '", base.application.getProgramDir(),"'"
		END IF
	END IF
	LET dos = FALSE
	IF fgl_getenv("OS") = "Windows_NT" THEN
		LET sla = "\\"
		LET cs = "&"
		DISPLAY "Running on Windows"
		LET dos = TRUE
		LET editfile = "fglrun ..",sla,"proglaunch"
	ELSE
		DISPLAY "Running on Linux/Unix"
		LET editfile = "fglrun ", base.application.getProgramDir()
	END IF
	LET editfile = editfile CLIPPED,sla,"editfile"
	IF debug THEN	
		DISPLAY "Editor:", editfile CLIPPED
	END IF

--	CALL init_genero()

	DISPLAY "Populating arrays."

	LET cnl1 = base.Channel.create()

	CALL fill_dir_arr()

	DISPLAY "Finished populating arrays."


END FUNCTION
--------------------------------------------------------------------------------
FUNCTION fill_dir_arr()
	DEFINE x,lev SMALLINT
	DEFINE dirname STRING
	DEFINE dn ARRAY[5] OF  STRING
	DEFINE tok base.StringTokenizer
	DEFINE node om.DomNode

	LET dir_cnt = 0
	IF dos THEN
		LET cmd = "cd ",cwd CLIPPED," && dir /ad /b * "
	ELSE
		LET cmd = "find ",cwd CLIPPED," -type d -maxdepth 4 | grep -v '\\./\\.' | sort"
	END IF
	IF debug THEN
		DISPLAY "cmd:",cmd CLIPPED
	END IF
	CALL cnl1.openpipe( cmd,"r")
	CALL read_nme("D")
	CALL cnl1.close()

	CALL njm_sm_create(TRUE,"")
	CLOSE WINDOW SCREEN
	CALL gl_prog_bar(4,dir_cnt,0,"Generating StartMenu, please wait...")
	FOR x = 1 TO dir_cnt
		LET dirname = dir_name[x]
--		DISPLAY dir_name[x] CLIPPED
		LET tok = base.StringTokenizer.create( dirname, sla )
		LET lev= 0
		WHILE tok.hasMoreTokens()
			LET lev = lev + 1
			LET dn[lev] = tok.nextToken()
		END WHILE
		LET node = njm_sm_add(TRUE,lev,"G",dn[lev],"test")
		IF NOT find_4gl(lev+1,dirname) THEN
			CALL node.removeChild( node )
		END IF
		CALL gl_prog_bar(5,dir_cnt,x,"")
	END FOR
	CALL gl_prog_bar(6,dir_cnt,0,"")

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION find_4gl(lev,dirname)
	DEFINE x,lev SMALLINT
	DEFINE dirname,modname,ext STRING
	DEFINE tok base.StringTokenizer
	DEFINE node om.DomNode

	IF dos THEN
		LET cmd = "cd ",cwd CLIPPED,sla,dirname.trim() CLIPPED
		LET cmd = cmd CLIPPED,cs,' find . -type f -maxdepth 1 | grep ".per\\|.4gl"| sort'
	ELSE
		LET cmd = "cd ",cwd CLIPPED,sla,dirname.trim() CLIPPED
		LET cmd = cmd CLIPPED,cs," find . -type f -maxdepth 1 | grep '.per\\|.4gl'| sort"
	END IF
	IF debug THEN
		DISPLAY "cmd:",cmd CLIPPED
	END IF

	CALL cnl1.openpipe(cmd,"r")
	LET mod_cnt = 0
	CALL read_nme("m")
	CALL cnl1.close()

	FOR x = 1 TO mod_cnt
		IF dos THEN
			LET modname = mod_name[x][2,30]
		ELSE
			LET modname = mod_name[x][3,30]
		END IF
		LET mod_name[x] = modname
		LET tok = base.StringTokenizer.create( modname, "." )
		WHILE tok.hasMoreTokens()
		 	LET ext = tok.nextToken()
		END WHILE
		CASE ext
			WHEN "4gl" LET cmd = "cd ",cwd CLIPPED,sla,dirname CLIPPED,cs,editfile CLIPPED," ",modname
			WHEN "per" LET cmd = "cd ",cwd CLIPPED,sla,dirname CLIPPED,cs,editfile CLIPPED," ",modname
			WHEN "42r" LET cmd = "cd ",cwd CLIPPED,sla,dirname CLIPPED,cs,"fglrun ",modname
			WHEN "makefile" LET cmd = "cd ",cwd CLIPPED,sla,dirname CLIPPED,cs,"make"
			OTHERWISE LET cmd = "test"
		END CASE
--		DISPLAY modname CLIPPED,":",ext CLIPPED,":",cmd CLIPPED
		
		LET node = njm_sm_add(TRUE,lev,"C",mod_name[x],cmd CLIPPED)
	END FOR
	IF mod_cnt > 0 THEN
		LET cmd = "cd ",cwd CLIPPED,sla,dirname CLIPPED,cs,"make"
		LET node = njm_sm_add(TRUE,lev,"C","Make",cmd CLIPPED)
		LET newcmd = cmd CLIPPED," clean"
		LET node = njm_sm_add(TRUE,lev,"C","Make Clean",newcmd CLIPPED)
		LET newcmd = cmd CLIPPED," run"
		LET node = njm_sm_add(TRUE,lev,"C","Make Run",newcmd CLIPPED)
		RETURN TRUE
	ELSE
		RETURN FALSE
	END IF

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION fill_arr()

	IF fgl_getenv("OS") = "Windows_NT" THEN
		LET cmd = "dir /b *.4gl "
	ELSE
		LET cmd = "ls -1 ",cwd CLIPPED,sla,"*.4gl "
	END IF
	CALL cnl1.openpipe(cmd,"r")
	CALL read_nme("M")
	CALL cnl1.close()

	LET prg_cnt = 0
	LET cmd = cwd CLIPPED,sla,"makefile"
	CALL cnl1.openfile(cmd,"r")
	CALL read_nme("P")
	CALL cnl1.close()

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION read_nme(func)
	DEFINE func CHAR(1)
	DEFINE x SMALLINT
	DEFINE offset SMALLINT

	LET offset = LENGTH(cwd)+1
	IF fgl_getenv("OS") = "Windows_NT" THEN
		LET offset = 0
	END IF

	LET ret = 1
	WHILE ret = 1
		LET ret = cnl1.read([buffer.Buff1, buffer.Buff2,buffer.Buff3])
		IF ret = 1 THEN
			IF debug THEN DISPLAY "read_nme:",buffer.Buff1 CLIPPED END IF
			IF func = "D" THEN
				LET dir_cnt = dir_cnt + 1
				LET dir_name[dir_cnt] = buffer.Buff1[offset+1,128]
				IF dir_name[dir_cnt] = " "
				OR dir_name[dir_cnt] IS NULL THEN 
					IF tre_cnt > 1 THEN
						LET dir_name[dir_cnt] = ".."
					ELSE
						LET dir_cnt = dir_cnt - 1
						CONTINUE WHILE
					END IF
				END IF
				IF dir_cnt < 19 THEN
					DISPLAY dir_name[dir_cnt] TO dir_name[dir_cnt]
				END IF
			END IF
			IF func = "m" THEN
				LET mod_cnt = mod_cnt + 1
				LET mod_name[mod_cnt] = buffer.Buff1
			END IF
			IF func = "M" THEN
				LET mod_cnt = mod_cnt + 1
--				LET mod_name[mod_cnt] = buffer.Buff1
				FOR x = 1 TO 30
					IF buffer.Buff1[x+offset] != "." THEN
						LET mod_name[mod_cnt][x] = buffer.Buff1[x+offset]
					ELSE		
						EXIT FOR
					END IF
				END FOR
				IF mod_cnt < 19 THEN
					DISPLAY mod_name[mod_cnt] TO mod_name[mod_cnt]
				END IF
			END IF
			IF func = "P" THEN
				FOR x = 1 TO 30
					IF buffer.Buff1[x,x+5] = ".42r :" THEN
						LET prg_cnt = prg_cnt + 1
						LET prg_name[prg_cnt] = buffer.Buff1[1,x-1]
						IF prg_cnt < 19 THEN
							DISPLAY prg_name[prg_cnt] TO prg_name[prg_cnt]
						END IF
						EXIT FOR
					END IF
				END FOR
			END IF
			IF func = "E" THEN
				IF buffer.Buff1[1] != "|" THEN
					CALL cnl1.write(buffer.Buff1)
				END IF
			END IF
--			DISPLAY buffer.Buff1 CLIPPED
		END IF
	END WHILE

END FUNCTION
