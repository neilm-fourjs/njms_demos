
#+ General library code for Benchmarking
#+
#+ $Id: gl_bm.4gl 652 2011-04-13 13:40:21Z  $
DEFINE m_start,m_end DATETIME HOUR TO FRACTION(5)

FUNCTION bm_start()
	LET m_start = CURRENT
	DISPLAY "BM Start:",m_start
END FUNCTION

FUNCTION bm_end()
	DEFINE fname, line STRING
	DEFINE c base.Channel
	LET m_end = CURRENT

	LET line = "BM Start:",m_start," BM End:",m_end," Duration:", ( m_end - m_start )
	DISPLAY LINE
	LET fname = base.Application.getProgramName()||".bm"
	LET c = base.Channel.create()
	CALL c.openFile(fname,"a+")
	CALL c.writeLine(TODAY||": "||line)
	CALL c.close()
END FUNCTION