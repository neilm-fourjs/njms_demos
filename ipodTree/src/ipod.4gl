
-- A Genero 2.20 Demo
-- $Id: ipod.4gl 342 2015-07-03 11:54:51Z neilm $
-- Features: TreeView / SAX Handling / Sockets
--
-- The program can read an iTunes(tm) Music Library xml files import into a 
-- database.
-- By default the program will work without a database.
-- To use a database you must setup your fglprofile entries for your choosen
-- database and set IPOD_DBNAME = to the name of that database.

IMPORT os
IMPORT FGL genero_lib1

&include "genero_lib1.inc"

CONSTANT progTitle = "iTunes viewer - TreeView demo - Revision(%1)" 

CONSTANT p_version = "$Rev: 342 $"
CONSTANT p_progname = "ipodTree"
CONSTANT p_progdesc = "An iPod Tree Demo"
CONSTANT p_progauth = "Neil J.Martin"

CONSTANT IDLE_TIME = 300

&define ABOUT ON ACTION about \
	CALL gl_about( gl_verFmt(gl_version) )

DEFINE xml_d om.domDocument
DEFINE xml_r om.domNode

TYPE t_song RECORD
		sortby VARCHAR(140),
		genre VARCHAR(40),
		artist VARCHAR(40),
		album VARCHAR(40),
		year  CHAR(4),
		discno SMALLINT,
		trackno SMALLINT,
		title VARCHAR(40),
		dur CHAR(10),
		file VARCHAR(100),
		play_count SMALLINT,
		rating SMALLINT
	END RECORD

TYPE t_tree RECORD
		name STRING,
		year  CHAR(4),
		pid STRING,
		id STRING,
		img STRING, 
		expanded BOOLEAN
	END RECORD

TYPE t_tracks RECORD
		genre_key INTEGER,
		artist_key INTEGER,
		album_key INTEGER,
		trackno SMALLINT,
		title STRING,
		dur CHAR(10),
		file VARCHAR(100),
		play_count SMALLINT,
		rating STRING,
		image STRING
	END RECORD

DEFINE song_a DYNAMIC ARRAY OF t_song
DEFINE tree_a DYNAMIC ARRAY OF t_tree
DEFINE tracks_a DYNAMIC ARRAY OF t_tracks
DEFINE sel_tracks_a DYNAMIC ARRAY OF t_tracks
DEFINE genre_a DYNAMIC ARRAY OF RECORD
		genre STRING,
		genre_key INTEGER,
		artist_cnt INTEGER
	END RECORD
DEFINE artist_a DYNAMIC ARRAY OF RECORD
--		genre STRING,
		artist STRING,
		artist_key INTEGER,
		album_cnt INTEGER
	END RECORD
DEFINE album_a DYNAMIC ARRAY OF RECORD
		artist STRING,
		album_key INTEGER,
		artist_key INTEGER,
		genre_key INTEGER,
		album STRING,
		genre STRING,
		year CHAR(4)
	END RECORD

DEFINE f om.SaxDocumentHandler

DEFINE t_sec, t_min, t_hr, t_day INTEGER
DEFINE db VARCHAR(120)
DEFINE getAlbumArt, workFromDB BOOLEAN

MAIN
	DEFINE file STRING

	OPTIONS ON CLOSE APPLICATION CALL tidyup
	WHENEVER ERROR CALL gl_error

	CALL genero_lib1.gl_setInfo(p_version,"", "cd", p_progname, p_progdesc, p_progauth)
	CALL genero_lib1.gl_init("s",NULL,TRUE)

--	RUN "env > ipoddemo.env"
--	WHENEVER ERROR CALL erro
{
	DISPLAY CURRENT,":FGLSERVER:",fgl_getEnv("FGLSERVER")
	DISPLAY CURRENT,":FGLIMAGEPATH:",fgl_getEnv("FGLIMAGEPATH")
	DISPLAY CURRENT,":FGLPROFILE:",fgl_getEnv("FGLPROFILE")
	DISPLAY CURRENT,":FGLRESOURCEPATH:",fgl_getEnv("FGLRESOURCEPATH")
	DISPLAY CURRENT,":DBPATH:",fgl_getEnv("DBPATH")
	DISPLAY CURRENT,":FGLIMAGEPATH:",fgl_getEnv("FGLIMAGEPATH")
	DISPLAY CURRENT,":Opening form and displaying it."
}
	OPEN FORM win FROM "ipod"
	DISPLAY FORM win
	CALL fgl_setTitle("Loading, please wait ...")
	CALL ui.interface.refresh()

	LET file = "iTunes Music Library.xml"
	LET workFromDB = FALSE

	--CALL gldb_connect(NULL)
	--LET workFromDB = TRUE

-- This options loads the original iTunes .xml file using a SAX Handler.
-- This creates a much similer xml file called songs.xml

	IF ARG_VAL(1) = "LOAD" THEN
		CALL openLibrary( file )
	ELSE
		IF workFromDB THEN
			CALL db_read()
		ELSE
			LET file = "../ipodTree/etc/music.xml"
			IF os.path.exists( file ) THEN
				CALL openXML(file)
				CALL loadMusic()	
			ELSE
				CALL fgl_winMessage("Error", "'"||file||"' Doesn't Exist, try running again like this\nfglrun ipod.42r LOAD","exclamation")
			END IF
		END IF
	END IF

	CALL fgl_setTitle( SFMT(progTitle,gl_verFmt( p_version )))

	CALL song_a.clear() -- This array not needed now, just used to create tree from xml.

	LET getAlbumArt = TRUE
	CALL dispInfo()
	CALL mainDialog()

END MAIN
--------------------------------------------------------------------------------
FUNCTION mainDialog()
	DEFINE r_search, t_search, a_search STRING
	DEFINE n om.DomNode

	DISPLAY CURRENT,": Starting main dialog."
	DISPLAY "noimage" TO album_art
	DIALOG ATTRIBUTES(UNBUFFERED)
		DISPLAY ARRAY tree_a TO tree.*
			BEFORE ROW
				MESSAGE "Current Row:",ARR_CURR()
				IF tree_a.getLength() > 0 THEN
					CALL loadTracks( tree_a[ arr_curr() ].id )
				END IF
			ON ACTION search
				NEXT FIELD search
			ON UPDATE
				CALL upd_tree_item( arr_curr(), scr_line() )
		END DISPLAY

		INPUT BY NAME r_search, a_search, t_search ATTRIBUTES(WITHOUT DEFAULTS=TRUE)
			ON ACTION t_search
				IF t_search.getLength() > 0 THEN
					IF workFromDB THEN
						CALL t_searchDB( t_search )
					ELSE
						CALL t_searchARR( t_search )
					END IF
				END IF
			ON ACTION a_search
				IF a_search.getLength() > 0 THEN
					IF workFromDB THEN
						CALL al_searchDB( a_search )
					ELSE
						CALL al_searchARR( a_search )
					END IF
				END IF
			ON ACTION r_search
				IF r_search.getLength() > 0 THEN
					IF workFromDB THEN
						CALL ar_searchDB( r_search )
					ELSE
						CALL ar_searchARR( r_search )
					END IF
				END IF
		END INPUT

		DISPLAY ARRAY sel_tracks_a TO tracks.*
			ON ACTION search
				NEXT FIELD r_search
			BEFORE ROW
				IF arr_curr() > 0 THEN
					CALL dispRowDetails(
						sel_tracks_a[ arr_curr() ].genre_key, 
						sel_tracks_a[ arr_curr() ].artist_key,
						sel_tracks_a[ arr_curr() ].album_key)
				END IF
		END DISPLAY

		INPUT BY NAME getAlbumArt ATTRIBUTES(WITHOUT DEFAULTS=TRUE)
			ON ACTION search
				NEXT FIELD r_search
			ON CHANGE getalbumart
				IF NOT getAlbumArt THEN
					DISPLAY "noimage" TO album_art
				END IF
		END INPUT

		BEFORE DIALOG
			CALL DIALOG.setSelectionMode("tree",TRUE)
			LET n = ui.Interface.getRootNode()

		ON ACTION open CALL openLibrary(NULL)
		ON ACTION close EXIT DIALOG
		ABOUT
		ON ACTION quit EXIT DIALOG

		ON ACTION dump CALL n.writeXml("aui.xml")

		ON IDLE IDLE_TIME
			DISPLAY "IDLE Time reached."
			EXIT DIALOG
	END DIALOG

	DISPLAY CURRENT,": Program Finished."
END FUNCTION
FUNCTION upd_tree_item( l_row, l_scr )
	DEFINE l_row, l_scr SMALLINT
	INPUT tree_a[l_row].name FROM tree[l_scr].name
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION dispInfo()

	LET t_hr = t_sec / 3600
	LET t_min = t_hr / 60
	LET t_sec = t_hr - ( t_min * 60 )
	LET t_day = t_hr / 24
	LET t_hr = t_hr - ( t_day * 24 )

	DISPLAY genre_a.getLength() TO genres
	DISPLAY artist_a.getLength() TO artists
	DISPLAY album_a.getLength() TO albums
	DISPLAY tracks_a.getLength() TO tracks
	DISPLAY "Total Play Time: "||t_day||" Days "||t_hr||
					" hours "||t_min||" minutes "||t_sec||" seconds" TO playtime

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION openLibrary( file )
	DEFINE file STRING

	IF file IS NULL THEN
		CALL ui.interface.frontCall("standard","openfile",
			["","iTunes Library","*.xml","Choose a Library"], file)
	END IF
	IF file IS NULL THEN
		MESSAGE "Cancelled."	
		RETURN
	END IF

	IF NOT os.path.exists( file ) THEN
		CALL fgl_winMessage("Error", "'"||file||"' Doesn't Exist, can't do load","exclamation")
		RETURN
	END IF

	CALL fgl_setTitle("Loading, please wait ...")
	CALL ui.interface.refresh()

	LET f = om.SaxDocumentHandler.createForName("ipod_sax")
	CALL f.readXmlFile( file )

	CALL loadSongs()

	IF workFromDB THEN
		CALL db_mk_tab()
		CALL db_load_tab()
	END IF
	CALL dispInfo()
	CALL fgl_setTitle(progTitle)

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION openXML( file )
	DEFINE file STRING

	DISPLAY CURRENT,": Opening "||file||" ..."
	LET xml_d = om.domDocument.createFromXMLFile(file)
	IF xml_d IS NULL THEN
		CALL fgl_winMessage("Error", "Failed to open '"||file||"'!\nTry running like this: fglrun ipod.42r LOAD","exclamation")
		EXIT PROGRAM
	END IF
	LET xml_r = xml_d.getDocumentElement()	
	IF xml_r IS NULL THEN
		CALL fgl_winMessage("Error", "Failed to get root node!","exclamation")
		EXIT PROGRAM
	END IF

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION t_searchARR( what )
	DEFINE tmp,what STRING
	DEFINE x INTEGER

	CALL showBranch( 0,0,0, FALSE )
	CALL sel_tracks_a.clear()
	FOR x = 1 TO tracks_a.getLength()
		LET tmp = tracks_a[x].title.toUpperCase()
		IF tmp.getIndexOf( what.toUpperCase(), 1 ) > 0 THEN
			CALL setSelTrack( x )
		END IF
	END FOR
	DISPLAY sel_tracks_a.getLength() TO nooftracks
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION ar_searchARR( what )
	DEFINE tmp,what STRING
	DEFINE x,y INTEGER

	MESSAGE "Searching for Artist matching '"||what||"'"
	CALL showBranch( 0,0,0, FALSE )
	CALL sel_tracks_a.clear()
	FOR x = 1 TO artist_a.getLength()
		LET tmp = artist_a[x].artist.toUpperCase()
		IF tmp.getIndexOf( what.toUpperCase(), 1 ) > 0 THEN
			FOR y = 1 TO tracks_a.getLength()
				IF tracks_a[y].artist_key != artist_a[x].artist_key THEN CONTINUE FOR END IF
				CALL setSelTrack( y )
			END FOR
			CALL showBranch( 0,artist_a[x].artist_key,0, TRUE )
		END IF
	END FOR
	DISPLAY sel_tracks_a.getLength() TO nooftracks
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION al_searchARR( what )
	DEFINE tmp, what STRING
	DEFINE x,y INTEGER

	CALL showBranch( 0,0,0, FALSE )
	CALL sel_tracks_a.clear()
	FOR x = 1 TO album_a.getLength()
		LET tmp = album_a[x].album.toUpperCase()
		IF tmp.getIndexOf( what.toUpperCase(), 1 ) > 0 THEN
			FOR y = 1 TO tracks_a.getLength()
				IF tracks_a[y].album_key != album_a[x].album_key THEN CONTINUE FOR END IF
				CALL setSelTrack( y )
			END FOR
			CALL showBranch( 0,artist_a[x].artist_key,album_a[x].album_key, TRUE )
		END IF
	END FOR
	DISPLAY sel_tracks_a.getLength() TO nooftracks
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION t_searchDB( what )
	DEFINE what STRING

	CALL showBranch( 0,0,0, FALSE )
	CALL sel_tracks_a.clear()
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION ar_searchDB( what )
	DEFINE what STRING

	CALL showBranch( 0,0,0, FALSE )
	CALL sel_tracks_a.clear()
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION al_searchDB( what )
	DEFINE what STRING

	CALL showBranch( 0,0,0, FALSE )
	CALL sel_tracks_a.clear()
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION loadMusic()
	DEFINE x, y, z, k INTEGER
	DEFINE xml_g, xml_ar, xml_al, xml_tr om.domNode
	DEFINE nl, nl2, nl3 om.nodeList

	CALL genre_a.clear()
	CALL artist_a.clear()
	CALL album_a.clear()
	CALL tracks_a.clear()
 
	DISPLAY CURRENT,": Loading from XML into array ..."
	LET nl = xml_r.selectByTagName("Genre") 
	FOR x = 1 TO nl.getlength()
		LET xml_g = nl.item(x)
		LET k = xml_g.getAttribute("genre_key")
		LET genre_a[k].genre = xml_g.getAttribute("name")
		LET genre_a[k].genre_key = k
		LET nl2 = xml_g.selectByTagName("Artist")
		LET genre_a[k].artist_cnt = nl2.getLength()
		FOR y = 1 TO nl2.getLength()
			LET xml_ar = nl2.item(y)
			LET k = xml_ar.getAttribute("artist_key")
			LET artist_a[k].artist = xml_ar.getAttribute("name")
			LET artist_a[k].artist_key = k
			LET nl3 = xml_ar.selectByTagName("Album")
			FOR z = 1 TO nl3.getLength()
				LET xml_al = nl3.item(z)
				LET k = xml_al.getAttribute("album_key")
				LET album_a[k].album = xml_al.getAttribute("name")
				LET album_a[k].album_key = k
				LET album_a[k].artist_key = xml_al.getAttribute("artist_key")
				LET album_a[k].genre_key = xml_al.getAttribute("genre_key")
				LET album_a[k].year = xml_al.getAttribute("year")
				LET album_a[k].genre = xml_g.getAttribute("name")
				LET album_a[k].artist = xml_ar.getAttribute("name")
			END FOR
		END FOR
	END FOR

	LET nl = xml_r.selectByTagName("Track") 
	FOR x = 1 TO nl.getlength()
		LET xml_tr = nl.item(x)
		LET tracks_a[x].dur = xml_tr.getAttribute("dur")
		LET tracks_a[x].genre_key = xml_tr.getAttribute("genre_key")
		LET tracks_a[x].album_key = xml_tr.getAttribute("album_key")
		LET tracks_a[x].artist_key = xml_tr.getAttribute("artist_key")
		LET tracks_a[x].title = xml_tr.getAttribute("title")
		LET tracks_a[x].trackno = xml_tr.getAttribute("trackno")
		LET tracks_a[x].file = xml_tr.getAttribute("file")
		LET tracks_a[x].play_count = xml_tr.getAttribute("play_count")
		LET tracks_a[x].rating = xml_tr.getAttribute("rating")
		LET t_min = t_min + tracks_a[x].dur[1,2]
		LET t_sec = t_sec + tracks_a[x].dur[4,5]
	END FOR
	CALL buildTree()
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION set_xml_n( n ) -- Called from SAX Handler.
	DEFINE n om.domNode
	
	LET xml_r = n

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION loadSongs()
	DEFINE x, gk, ark, alk INTEGER
	DEFINE trck,c om.domNode
	DEFINE tim, hr,minu,sec,navg, pavg INTEGER
	DEFINE song t_song
--	DEFINE xml_d om.domDocument
	DEFINE xml_g, xml_ar, xml_al, xml_tr om.domNode
	DEFINE nl om.nodeList

	CALL song_a.clear()
	CALL genre_a.clear()
	CALL artist_a.clear()
	CALL album_a.clear()
	CALL tracks_a.clear()

	LET t_sec = 0
	LET t_min = 0
	LET t_hr  = 0
	LET t_day = 0

	DISPLAY CURRENT,": Nodes:",xml_r.getChildCount(), ":",xml_r.getTagName()

	LET trck = xml_r.getFirstChild()
	LET x = 0
	DISPLAY CURRENT,": Loading from XML into array & sorting ..."

	CALL gl_progBar(1,100,"Processing XML - Phase 1 of 3")
	LET pavg = 0
	WHILE trck IS NOT NULL
		LET navg = (( x / song_a.getLength()) * 100 )
		IF pavg != navg THEN
			LET pavg = navg
			CALL gl_progBar(2, pavg,"")
		END IF
		LET song.title = trck.getAttribute("name")
		IF song.title IS NULL OR song.title = " " THEN
			LET trck = trck.getNext()
			CONTINUE WHILE
		END IF
		LET song.artist = trck.getAttribute("artist")
		IF song.artist IS NULL OR LENGTH(song.artist CLIPPED) < 1 THEN
			LET song.artist = "(null)"
		END IF
		LET song.album = trck.getAttribute("album")
		IF song.album IS NULL OR LENGTH(song.album CLIPPED) < 1 THEN
			LET song.album = "(null)"
		END IF
		LET song.genre  = trck.getAttribute("genre")
		IF song.genre IS NULL OR LENGTH(song.genre CLIPPED) < 1 THEN
			LET song.genre = "(null)"
		END IF
		LET song.discno = trck.getAttribute("disc_number")
		IF song.discno IS NULL THEN LET song.discno = 0 END IF
		LET song.trackno = trck.getAttribute("track_number")
		IF song.trackno IS NULL THEN LET song.trackno = 0 END IF
		LET song.year = trck.getAttribute("year")
		LET song.play_count = trck.getAttribute("play_count")
		LET song.rating = trck.getAttribute("rating")
		LET tim = trck.getAttribute("total_time")
		IF tim IS NOT NULL THEN
			LET hr = tim / 1000
			LET minu = hr / 60
			LET sec = hr - ( minu * 60 )
			LET song.dur = minu USING "&&",":", sec USING "&&"
			LET t_sec = t_sec + ( tim / 1000 )
			LET t_min = t_min + minu
		END IF
		LET c = trck.getFirstChild()
		IF c IS NOT NULL THEN
			LET song.file = c.getAttribute("@chars")
		END IF
		CALL sortSongs( song.* )
		LET trck = trck.getNext()
	END WHILE

	DISPLAY CURRENT,": Building Sub Arrays & music.xml ..."

	LET xml_d = om.domdocument.create("Music")
	LET xml_r = xml_d.getdocumentelement()
	CALL gl_progBar(3,0,"")
	CALL gl_progBar(1,100,"Processing XML - Phase 2 of 3")
	LET pavg = 0
	FOR x = 1 TO song_a.getLength()
		LET navg = (( x / song_a.getLength()) * 100 )
		IF pavg != navg THEN
			LET pavg = navg
			CALL gl_progBar(2, pavg,"")
		END IF
		FOR gk = 1 TO genre_a.getLength()
			IF genre_a[gk].genre = song_a[x].genre THEN EXIT FOR END IF
		END FOR
		IF gk > genre_a.getLength() THEN 
			LET genre_a[ genre_a.getLength() + 1 ].genre = song_a[x].genre
			LET genre_a[ genre_a.getLength()].genre_key = gk 
			LET xml_g = xml_r.createChild("Genre")
			CALL xml_g.setAttribute("name", genre_a[ genre_a.getLength()].genre )
			CALL xml_g.setAttribute("genre_key", genre_a[ genre_a.getLength()].genre_key )
		END IF
		FOR ark = 1 TO artist_a.getLength()
			IF artist_a[ark].artist = song_a[x].artist THEN EXIT FOR END IF
		END FOR
		IF ark > artist_a.getLength() THEN 
			LET artist_a[ artist_a.getLength() + 1 ].artist = song_a[x].artist 
--			LET artist_a[ artist_a.getLength()].genre = song_a[x].genre
			LET artist_a[ artist_a.getLength()].artist_key = ark
			LET xml_ar = xml_g.createChild("Artist")
			CALL xml_ar.setAttribute("name", artist_a[ artist_a.getLength()].artist )
			CALL xml_ar.setAttribute("artist_key", artist_a[ artist_a.getLength()].artist_key )
			CALL xml_ar.setAttribute("genre_key", gk )
		END IF
		FOR alk = 1 TO album_a.getLength()
			IF album_a[alk].album = song_a[x].album THEN EXIT FOR END IF
		END FOR
		IF alk > album_a.getLength() THEN
			LET album_a[ album_a.getLength() + 1 ].artist = song_a[x].artist 
			LET album_a[ album_a.getLength()].album = song_a[x].album
			LET album_a[ album_a.getLength()].year = song_a[x].year
			LET album_a[ album_a.getLength()].genre = song_a[x].genre
			LET album_a[ album_a.getLength()].album_key = alk
			LET album_a[ album_a.getLength()].artist_key = ark
			LET nl = xml_g.selectbypath("//Artist[@artist_key='"||ark||"']")
			IF nl.getlength() > 0 THEN
				LET xml_ar = nl.item(1)
			ELSE
				LET nl = xml_r.selectbypath("//Artist[@artist_key='"||ark||"']") 
				IF nl.getlength() > 0 THEN
					LET xml_ar = xml_g.createChild("Artist")
					CALL xml_ar.setAttribute("name", album_a[ album_a.getLength() ].artist )
					CALL xml_ar.setAttribute("artist_key", ark )
					CALL xml_ar.setAttribute("genre_key", gk )
				ELSE
					DISPLAY "Failed to find Artist!   //Artist[@artist_key='"||ark||"']"
				END IF
			END IF
			LET xml_al = xml_ar.createChild("Album")
			CALL xml_al.setAttribute("name", album_a[ album_a.getLength()].album )
			CALL xml_al.setAttribute("album_key", album_a[ album_a.getLength()].album_key )
			CALL xml_al.setAttribute("year", song_a[x].year )
			CALL xml_al.setAttribute("artist_key", ark )
			CALL xml_al.setAttribute("genre_key", gk )
		END IF
		LET xml_tr = xml_ar.createChild("Track")
		CALL xml_tr.setAttribute("album_key", alk )
		CALL xml_tr.setAttribute("artist_key", ark )
		CALL xml_tr.setAttribute("genre_key", gk )
		CALL xml_tr.setAttribute("title", song_a[x].title )
		CALL xml_tr.setAttribute("trackno", song_a[x].trackno )
		CALL xml_tr.setAttribute("dur", song_a[x].dur CLIPPED )
		CALL xml_tr.setAttribute("file", song_a[x].file CLIPPED )
		CALL xml_tr.setAttribute("play_count", song_a[x].play_count )
		CALL xml_tr.setAttribute("rating", song_a[x].rating )
		LET tracks_a[ tracks_a.getLength() + 1 ].genre_key = gk
		LET tracks_a[ tracks_a.getLength()     ].artist_key = ark
		LET tracks_a[ tracks_a.getLength()     ].album_key = alk
		LET tracks_a[ tracks_a.getLength()     ].trackno = song_a[x].trackno
		LET tracks_a[ tracks_a.getLength()     ].title = song_a[x].title CLIPPED
		LET tracks_a[ tracks_a.getLength()     ].dur = song_a[x].dur CLIPPED
		LET tracks_a[ tracks_a.getLength()     ].file = song_a[x].file CLIPPED
		LET tracks_a[ tracks_a.getLength()     ].play_count = song_a[x].play_count
		LET tracks_a[ tracks_a.getLength()     ].rating = song_a[x].rating
	END FOR
	CALL xml_r.writeXML("music.xml")
	CALL gl_progBar(3,0,"")
	CALL buildTree()

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION sortsongs( s )
	DEFINE s t_song
	DEFINE x INTEGER
	
	LET s.sortby = DOWNSHIFT(s.genre||"-"||s.artist)
	FOR x = 1 TO song_a.getLength()
		IF song_a[ x ].sortby > s.sortby THEN
			--DISPLAY x,":",song_a[x].sortBy,":",s.sortBy
			CALL song_a.insertElement( x )
			EXIT FOR
		END IF
	END FOR
	LET song_a[ x ].* = s.*

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION buildTree()
	DEFINE x, y, g, a, t_cnt, album_cnt INTEGER
	DEFINE prev_art STRING

	CALL gl_progBar(1,genre_a.getLength(),"Processing XML - Phase 3 of 3")

	CALL tree_a.clear()
	DISPLAY CURRENT,": Genre:"||genre_a.getLength()||
					" Artists:"||artist_a.getLength()||
					" Albums:"||album_a.getLength()||
					" Tracks:"||tracks_a.getLength()
	DISPLAY CURRENT,": Building Tree ..."
	LET t_cnt = 1
	FOR x = 1 TO genre_a.getLength()
		LET tree_a[ t_cnt ].id = (genre_a[x].genre_key USING "&&&&&")
		LET g = t_cnt
		LET genre_a[x].artist_cnt = 0
		LET t_cnt = t_cnt + 1
		LET prev_art = "."
		CALL gl_progBar(2, x,"")
		FOR y = 1 TO album_a.getLength()
			IF album_a[y].genre = genre_a[x].genre THEN
				IF album_a[y].artist != prev_art THEN
					LET genre_a[x].artist_cnt = genre_a[x].artist_cnt  + 1
					LET tree_a[ t_cnt ].img = "user"
					LET tree_a[ t_cnt ].pid = (genre_a[x].genre_key USING "&&&&&")
					LET tree_a[ t_cnt ].id = (genre_a[x].genre_key USING "&&&&&")||"-"||(album_a[y].artist_key USING "&&&&&")
					LET a = t_cnt
					LET t_cnt = t_cnt + 1
					LET prev_art = album_a[y].artist
					LET album_cnt = 0
				END IF
				LET album_cnt = album_cnt + 1
				LET tree_a[ t_cnt ].img = "cd16"
				LET tree_a[ t_cnt ].name = album_a[y].album
				LET tree_a[ t_cnt ].year = album_a[y].year
				LET tree_a[ t_cnt ].pid = (genre_a[x].genre_key USING "&&&&&")||"-"||(album_a[y].artist_key USING "&&&&&")
				LET tree_a[ t_cnt ].id = (genre_a[x].genre_key USING "&&&&&")||"-"||(album_a[y].artist_key USING "&&&&&")||"-"||(album_a[y].album_key USING "&&&&&")

				LET t_cnt = t_cnt + 1
				LET tree_a[ a ].name = album_a[y].artist||" ("||album_cnt||")"
			END IF
		END FOR
		LET tree_a[ g ].name = genre_a[x].genre||" ("||genre_a[x].artist_cnt||")"
	END FOR

	FOR x = 1 TO tree_a.getLength()
		DISPLAY tree_a[ x ].id, " PID:", tree_a[ x ].pid, " NAME:",tree_a[ x ].name
	END FOR
	CALL gl_progBar(3,0,"")
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION showBranch( g, ar, al, tf )
	DEFINE g, ar, al INTEGER
	DEFINE tf BOOLEAN
	DEFINE y,x INTEGER
	DEFINE id1, id2, id3 CHAR(5)
	DEFINE d ui.Dialog

	LET d = ui.dialog.getCurrent()

	LET id1 = (g USING "&&&&&")
	LET id2 = (ar USING "&&&&&")
	LET id3 = (al USING "&&&&&")
	DISPLAY "Id:",id1,"-",id2,"-",id3

	IF g =0 AND al = 0 AND ar = 0 THEN
		FOR y = 1 TO tree_a.getLength()
			LET tree_a[y].expanded = tf
		END FOR
		RETURN
	END IF

	IF al > 0 THEN
		FOR y = 1 TO tree_a.getLength() -- Expand branches for albums found.
			IF tree_a[y].id.subString(13,17) = id3 THEN
				LET tree_a[y].expanded = tf
	--			CALL d.setSelectionRange("tree",y,y,TRUE)
			--ELSE
				--LET tree_a[y].expanded = NOT tf
			END IF
		END FOR
	END IF
	IF ar > 0 THEN
		FOR y = 1 TO tree_a.getLength() -- Expand branches for artist found.
			IF tree_a[y].id.subString(7,11) = id2 THEN
				LET tree_a[y].expanded = tf
	--			CALL d.setSelectionRange("tree",y,y,TRUE)
			--ELSE
				--LET tree_a[y].expanded = NOT tf
			END IF
		END FOR
	END IF

-- Fixes genre according to any expanded children
	FOR y = 1 TO tree_a.getLength() -- Expand/Collapse branches for genre found.
		IF tree_a[y].id.getLength() = 5 THEN
			LET tree_a[y].expanded = FALSE
			FOR x = y+1 TO tree_a.getLength()
				IF tree_a[x].id.subString(1,5) != tree_a[y].id.subString(1,5) THEN EXIT FOR END IF
				IF tree_a[x].expanded THEN -- if child expanded.
					LET tree_a[y].expanded = TRUE -- Expand parent
					EXIT FOR
				END IF
			END FOR
		END IF
	END FOR

-- Now see if they wanted to expand any specific genre.
	IF g > 0 THEN
		FOR y = 1 TO tree_a.getLength() -- Expand branches for genre found.
			IF tree_a[y].id.subString(1,5) = id1 AND tree_a[y].id.getLength() = 5 THEN
				LET tree_a[y].expanded = tf
	--			CALL d.setSelectionRange("tree",y,y,TRUE)
			ELSE
				LET tree_a[y].expanded = NOT tf
			END IF
		END FOR
	END IF
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION dispRowDetails(g, art, alb)
	DEFINE g, art, alb, x INTEGER
	DEFINE album_name STRING
	DEFINE id STRING
	DEFINE d ui.dialog

	IF alb > 0 THEN LET album_name = album_a[ alb ].album END IF
	LET id = (g USING "&&&&&")||"-"||(art USING "&&&&&")||"-"||(alb USING "&&&&&")

	DISPLAY CURRENT,": Track Row G:",g," Art:",art," Alb:",alb," ID:",id

	IF g IS NOT NULL THEN
		DISPLAY genre_a[ g ].genre TO genre
		LET g = 0
	END IF
	DISPLAY artist_a[ art ].artist TO artist
	DISPLAY album_name TO album
	DISPLAY sel_tracks_a.getLength() TO nooftracks

	IF id IS NOT NULL THEN
		FOR x = 1 TO tree_a.getLength()
			IF tree_a[x].id = id THEN
				LET d = ui.dialog.getCurrent()
				CALL d.setCurrentRow("tree",x)
				DISPLAY "Found Tree node! : ", x
				EXIT FOR
			END IF
		END FOR
	END IF

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION loadTracks( id )
	DEFINE id STRING
	DEFINE g, art, alb, x, y INTEGER
	DEFINE tracks_tmp DYNAMIC ARRAY OF t_tracks

-- 12345678901234567
-- 00000-00000-00000

	LET g   = id.subString(  1,  5 )
	LET art = id.subString(  7, 11 )
	LET alb = id.subString( 13, 17 )

	IF art IS NULL THEN RETURN END IF
	IF alb IS NULL THEN LET alb = 0 END IF
	DISPLAY CURRENT,": Loading Tracks - ID:",id," G:",g," Art:",art," Alb:",alb

	CALL sel_tracks_a.clear()
	IF art > 0 THEN
		FOR x = 1 TO tracks_a.getLength()
			IF tracks_a[x].artist_key = art THEN
				IF alb = 0 OR tracks_a[x].album_key = alb THEN
					LET tracks_tmp[ tracks_tmp.getLength() + 1 ].genre_key = tracks_a[x].genre_key
					LET tracks_tmp[ tracks_tmp.getLength() ].artist_key = tracks_a[x].artist_key
					LET tracks_tmp[ tracks_tmp.getLength() ].album_key = tracks_a[x].album_key
					LET tracks_tmp[ tracks_tmp.getLength() ].title = tracks_a[x].title
					LET tracks_tmp[ tracks_tmp.getLength() ].trackno = tracks_a[x].trackno 
					LET tracks_tmp[ tracks_tmp.getLength() ].image = "note"
					LET tracks_tmp[ tracks_tmp.getLength() ].dur = tracks_a[x].dur
					LET tracks_tmp[ tracks_tmp.getLength() ].file = tracks_a[x].file
					LET tracks_tmp[ tracks_tmp.getLength() ].play_count = tracks_a[x].play_count
					LET tracks_tmp[ tracks_tmp.getLength() ].rating = tracks_a[x].rating
					IF tracks_a[x].rating IS NULL THEN LET tracks_a[x].rating = 0 END IF
					LET tracks_tmp[ tracks_tmp.getLength() ].rating = tracks_a[x].rating USING "<&&"
				END IF
			END IF
		END FOR
	END IF
-- Now sort track list my trackNo.
	FOR y = 0 TO 60
		FOR x = 1 TO tracks_tmp.getLength()
			IF y = tracks_tmp[x].trackno THEN
				LET sel_tracks_a[ sel_tracks_a.getLength() + 1 ].* = tracks_tmp[ x ].*
			END IF
		END FOR
	END FOR

	CALL dispRowDetails(g, art, alb)
	DISPLAY "noimage" TO album_art
	CALL ui.interface.refresh()

	IF getAlbumArt AND alb > 0 THEN
		DISPLAY getAlbumArtURL(artist_a[ art ].artist, album_a[ alb ].album ) TO album_art
	END IF

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION setSelTrack( x )
	DEFINE x INTEGER

	LET sel_tracks_a[ sel_tracks_a.getLength() + 1 ].genre_key = tracks_a[x].genre_key
	LET sel_tracks_a[ sel_tracks_a.getLength() ].artist_key = tracks_a[x].artist_key
	LET sel_tracks_a[ sel_tracks_a.getLength() ].album_key = tracks_a[x].album_key
	LET sel_tracks_a[ sel_tracks_a.getLength() ].title = tracks_a[x].title
	LET sel_tracks_a[ sel_tracks_a.getLength() ].trackno = tracks_a[x].trackno 
	LET sel_tracks_a[ sel_tracks_a.getLength() ].image = "note"
	LET sel_tracks_a[ sel_tracks_a.getLength() ].dur = tracks_a[x].dur
	LET sel_tracks_a[ sel_tracks_a.getLength() ].file = tracks_a[x].file
	LET sel_tracks_a[ sel_tracks_a.getLength() ].play_count = tracks_a[x].play_count
	IF tracks_a[x].rating IS NULL THEN LET tracks_a[x].rating = 0 END IF
	LET sel_tracks_a[ sel_tracks_a.getLength() ].rating = tracks_a[x].rating USING "&&"

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION getAlbumArtURL( art, alb )
	DEFINE art, alb, url, line, img STRING
	DEFINE x,y INTEGER
	DEFINE tmp base.StringBuffer
	DEFINE gotDiv, eof BOOLEAN
	DEFINE soc base.channel
	
	LET tmp = base.stringBuffer.create()
	CALL tmp.append(art||"+"||alb)
	CALL tmp.replace(" ","+",0)
	LET art = tmp.toString()

	LET img = "noimage"
	LET eof = FALSE

--	LET url = "http://albumart.org/index.php?srchkey=roger+waters+pros+cons&itempage=1&newsearch=1&searchindex=Music"
	LET url = "/index.php?srchkey="||art||"&itempage=1&newsearch=1&searchindex=Music"
	--DISPLAY CURRENT,": Attempting to fetch album art from:"
	DISPLAY CURRENT," http://albumart.org",url

	MESSAGE "getting album artwork..." CALL ui.Interface.refresh()
	LET soc = base.channel.create()
	TRY
		CALL soc.openClientSocket("albumart.org",80,"ub",15)
		--CALL s.openClientSocket("78.46.52.7",80,"ub",15)
	CATCH
		--DISPLAY CURRENT," :Failed to connect to albumart.org"
		MESSAGE "getting album artwork - Failed" CALL ui.Interface.refresh()
		LET getAlbumArt = FALSE
		RETURN "noimagewa"
	END TRY
	--DISPLAY CURRENT,": Connected, sending GET ... "

	CALL soc.writeLine("GET "||url||" HTTP/1.0\r")
	CALL soc.writeLine("\r")

	DISPLAY CURRENT,": Reading result ..."
	LET gotDiv = FALSE
	WHILE NOT eof
		LET line = soc.readLine()
		LET eof = soc.isEof()
		DISPLAY line
		LET x =  line.getIndexOf("main_left",1)
		IF x > 1 THEN LET gotDiv = TRUE END IF
		IF gotDiv THEN
			LET x =  line.getIndexOf("img src=\"",1)
			IF x > 1 THEN
				LET y =  line.getIndexOf("\"",x+9)
				LET img = line.subString(x+9,y-1)
				DISPLAY "IMG:",img
				EXIT WHILE
			END IF
		END IF
	END WHILE
	--DISPLAY CURRENT,": Done."

	CALL soc.close()
	IF img IS NULL OR img = "noimage" THEN
		MESSAGE "getting album artwork - Failed"
	END IF
	CALL ui.Interface.refresh()
--	LET img = "http://ecx.images-amazon.com/images/I/414M73KT6NL._SL160_.jpg"

	RETURN img
END FUNCTION
--------------------------------------------------------------------------------
--DB Functions.
--------------------------------------------------------------------------------
FUNCTION db_mk_tab()
	
	DISPLAY "Drop Tables ..."
	TRY
		DROP TABLE ipod_genre
	CATCH
	END TRY
	TRY
		DROP TABLE ipod_artists
	CATCH
	END TRY	
	TRY
		DROP TABLE ipod_albums
	CATCH
	END TRY
	TRY
		DROP TABLE ipod_tracks
	CATCH
	END TRY

	DISPLAY "Create Table  'ipod_genre'..."
	TRY
		CREATE TABLE ipod_genre (
			genre_key SERIAL,
			genre VARCHAR(40)
		)
	CATCH
		CALL fgl_winMessage("Error","failed to create 'ipod_genre'\n"||SQLERRMESSAGE,"exclamation")
		EXIT PROGRAM
	END TRY
	DISPLAY "Created Table 'ipod_genre'"	

	DISPLAY "Create Table  'ipod_artists'..."
	TRY
		CREATE TABLE ipod_artists (
			artist_key SERIAL,
			artist VARCHAR(50)
		)
	CATCH
		CALL fgl_winMessage("Error","failed to create 'ipod_artists'\n"||SQLERRMESSAGE,"exclamation")
		EXIT PROGRAM
	END TRY
	DISPLAY "Create Table 'ipod_artists'"	

	DISPLAY "Create Table  'ipod_albums'..."
	TRY
		CREATE TABLE ipod_albums (
			album_key SERIAL,
			genre_key INTEGER,
			artist_key INTEGER,
			album VARCHAR(50),
			year CHAR(4)
		)
	CATCH
		CALL fgl_winMessage("Error","failed to create 'ipod_albums'\n"||SQLERRMESSAGE,"exclamation")
		EXIT PROGRAM
	END TRY
	DISPLAY "Create Table 'ipod_albums'"	

	DISPLAY "Create Table  'ipod_tracks'..."
	TRY
		CREATE TABLE ipod_tracks (
			track_key SERIAL,
			album_key INTEGER,
			track_no SMALLINT,
			track VARCHAR(60),
			dur VARCHAR(10),
			file VARCHAR(100),
			play_count SMALLINT,
			rating SMALLINT
		)
	CATCH
		CALL fgl_winMessage("Error","failed to create 'ipod_tracks'\n"||SQLERRMESSAGE,"exclamation")
		EXIT PROGRAM
	END TRY
	DISPLAY "Create Table 'ipod_tracks'"

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION db_load_tab()
	DEFINE x, y, ak INTEGER
	DEFINE vc VARCHAR(60)

	DISPLAY CURRENT,":Loading "||genre_a.getLength()||" Genre ..."
	MESSAGE "Loading "||genre_a.getLength()||" Genre ..."
	CALL ui.interface.refresh()
	BEGIN WORK
	FOR x = 1 TO genre_a.getLength()
		LET vc = genre_a[x].genre
		INSERT INTO ipod_genre VALUES ( 0, vc )
		LET genre_a[x].genre_key = SQLCA.sqlerrd[2]
		--DISPLAY "Genre:",genre_a[x].genre,":",genre_a[x].genre_key
	END FOR
	COMMIT WORK

	DISPLAY CURRENT,":Loading "||artist_a.getLength()||" Artists ..."
	MESSAGE "Loading "||artist_a.getLength()||" Artists ..."
	CALL ui.interface.refresh()	
	DECLARE art_put_cur CURSOR FOR INSERT INTO ipod_artists VALUES ( 0, ? )
	BEGIN WORK
	OPEN art_put_cur
	FOR x = 1 TO artist_a.getLength()
		LET vc = artist_a[x].artist
-- NOTE: can't use PUT because it doesn't set SQLCA with last serial !!
		EXECUTE art_put_cur USING vc
		LET artist_a[x].artist_key = SQLCA.sqlerrd[2]
		--DISPLAY "Artist:",artist_a[x].artist,":",artist_a[x].artist_key
	END FOR
	CLOSE art_put_cur
	COMMIT WORK

	DISPLAY CURRENT,":Loading "||album_a.getLength()||" Albums ..."
	MESSAGE "Loading "||album_a.getLength()||" Albums ..."
	CALL ui.interface.refresh()	
	DECLARE alb_put_cur CURSOR FOR INSERT INTO ipod_albums VALUES ( 0, ?, ? , ?, ? )
	BEGIN WORK
	OPEN alb_put_cur
	FOR x = 1 TO album_a.getLength()
		LET vc = album_a[x].album
		FOR y = 1 TO genre_a.getLength()
			IF album_a[x].genre = genre_a[y].genre THEN
				LET album_a[x].genre_key = genre_a[y].genre_key
				EXIT FOR
			END IF
		END FOR
		FOR y = 1 TO artist_a.getLength()
			IF artist_a[y].artist IS NULL THEN CONTINUE FOR END IF
			IF album_a[x].artist = artist_a[y].artist THEN
				LET album_a[x].artist_key = artist_a[y].artist_key
				EXIT FOR
			END IF
		END FOR
		EXECUTE alb_put_cur USING album_a[x].genre_key, album_a[x].artist_key , vc, album_a[x].year
		LET album_a[x].album_key = SQLCA.sqlerrd[2]
		--DISPLAY "Album:",album_a[x].album,":",album_a[x].album_key, " Artist:",album_a[x].artist_key," Genre:",album_a[x].genre_key
	END FOR
	CLOSE alb_put_cur
	COMMIT WORK

	DISPLAY CURRENT,":Loading "||song_a.getLength()||" Tracks ..."
	MESSAGE "Loading "||song_a.getLength()||" Tracks ..."
	CALL ui.interface.refresh()	
	DECLARE sng_put_cur CURSOR FOR INSERT INTO ipod_tracks VALUES ( 0, ?, ?, ?, ?, ?, ?,?  )
	BEGIN WORK
	OPEN sng_put_cur
	FOR x = 1 TO song_a.getLength()
		LET vc = song_a[x].title
		FOR y = 1 TO album_a.getLength()
			IF song_a[x].artist = album_a[y].artist AND song_a[x].album = album_a[y].album THEN
				LET ak = album_a[y].album_key
			END IF
		END FOR
		PUT sng_put_cur FROM ak, song_a[x].trackno, vc, song_a[x].dur , song_a[x].file, song_a[x].play_count,song_a[x].rating
	END FOR
	CLOSE sng_put_cur
	COMMIT WORK

	SELECT COUNT(*) INTO x FROM ipod_tracks
	DISPLAY CURRENT,":Loaded "||x||" Songs..."

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION db_read()
	DEFINE vc, vc2, vc3 VARCHAR(60)
	DEFINE yr CHAR(4)
	DEFINE gk, ark, alk INTEGER
	DEFINE l_trk RECORD
			track_key INTEGER,
			album_key INTEGER,
			track_no SMALLINT,
			track VARCHAR(60),
			dur VARCHAR(10),
			file VARCHAR(100),
			play_count SMALLINT,
			rating SMALLINT
		END RECORD

	CALL genre_a.clear()
	CALL album_a.clear()
	CALL artist_a.clear()
	CALL tracks_a.clear()

	DISPLAY CURRENT,": Populating the arrays from database ..."
	DECLARE g_cur CURSOR FOR SELECT genre, genre_key FROM ipod_genre ORDER BY genre
	DECLARE a_cur CURSOR FOR 
		SELECT al.album, al.album_key, ar.artist, ar.artist_key, al.year
		FROM ipod_albums al, ipod_artists ar 
		WHERE al.genre_key = gk
			AND al.artist_key = ar.artist_key
		ORDER BY artist, album

	FOREACH g_cur INTO vc, gk
		LET genre_a[ gk ].genre = vc
		LET genre_a[ gk ].genre_key = gk
		FOREACH a_cur INTO vc2, alk, vc3, ark, yr
			--DISPLAY vc,":",vc2,":",vc3
			LET album_a[ alk  ].genre = vc
			LET album_a[ alk  ].genre_key = gk
			LET album_a[ alk  ].album = vc2
			LET album_a[ alk  ].album_key = alk
			LET album_a[ alk  ].artist = vc3
			LET album_a[ alk  ].artist_key = ark
			LET album_a[ alk  ].year = yr
			LET artist_a[ ark  ].artist = vc3
			LET artist_a[ ark  ].artist_key = ark
			--DISPLAY album_a[ alk ].*
		END FOREACH
	END FOREACH

	DECLARE t_cur CURSOR FOR SELECT ipod_tracks.*,artist_key FROM ipod_tracks t, ipod_albums a
		WHERE t.album_key = a.album_key
		ORDER BY t.album_key, track_no
	FOREACH t_cur INTO l_trk.*, ark
		LET tracks_a[ tracks_a.getLength() + 1 ].artist_key = ark
		LET tracks_a[ tracks_a.getLength()     ].album_key = l_trk.album_key
		LET tracks_a[ tracks_a.getLength()     ].trackno = l_trk.track_no
		LET tracks_a[ tracks_a.getLength()     ].title = l_trk.track
		LET tracks_a[ tracks_a.getLength()     ].dur = l_trk.dur
		LET tracks_a[ tracks_a.getLength()     ].file = l_trk.file
		LET tracks_a[ tracks_a.getLength()     ].play_count = l_trk.play_count
		LET tracks_a[ tracks_a.getLength()     ].rating = l_trk.rating
		LET t_min = t_min + tracks_a[ tracks_a.getLength() ].dur[1,2]
		LET t_sec = t_sec + tracks_a[ tracks_a.getLength() ].dur[4,5]
	END FOREACH

	CALL buildTree()

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION erro()
	DISPLAY "----------------------------------------------"
	IF STATUS != 0 THEN
		DISPLAY STATUS,":",SQLERRMESSAGE
	END IF
	DISPLAY base.application.getstacktrace()
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION webkit(what)
	DEFINE url,what STRING

	OPEN WINDOW webkit WITH FORM "webkit"
	LET int_flag = FALSE
	LET url = "http://www.4js.com/online_documentation/fjs-fgl-2.20.02-manual-html/"
	DISPLAY BY NAME url
	DISPLAY url TO browser
	WHILE NOT int_flag
		INPUT BY NAME url ATTRIBUTE(WITHOUT DEFAULTS,UNBUFFERED)
			ON ACTION exit EXIT INPUT
			ON ACTION close EXIT INPUT
			ON ACTION google LET url = "http://www.google.com/" EXIT INPUT
			ON ACTION fourjs LET url = "http://www.fourjs.com/" EXIT INPUT
			ON ACTION manual LET url = "http://www.4js.com/online_documentation/fjs-fgl-2.20.02-manual-html/" EXIT INPUT
		END INPUT
		IF NOT int_flag THEN 
			DISPLAY url TO browser
		END IF
	END WHILE
	CLOSE WINDOW webkit
	LET int_flag = FALSE
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION tidyup()
-- Oh dear, a timeout has been reach, must close nicely
	DISPLAY CURRENT,": Tidyup"
END FUNCTION
--------------------------------------------------------------------------------
