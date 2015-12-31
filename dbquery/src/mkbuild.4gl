
MAIN

	DEFINE cnl base.Channel
	DEFINE r STRING

	LET cnl = base.channel.create()
	CALL cnl.openFile("build.txt","r")
	LET r = cnl.readline()
	CALL cnl.close()
	
	CALL cnl.openFile("build.inc","w")
	CALL cnl.writeLine( "CONSTANT gl_build = "||r.trim() )
	CALL cnl.close()

END MAIN
