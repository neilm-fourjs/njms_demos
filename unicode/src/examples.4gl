
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
END GLOBALS

--------------------------------------------------------------------------------
FUNCTION set_rec1( lang,nam )
	DEFINE lang,nam STRING

	LET rec.lang = lang
	LET rec.c_text = "Intrusion"
	CASE lang
		WHEN "zh_CN.UTF-8"
			LET rec.c_text_t = "侵扰"
		WHEN "ko_KR.utf8"
			LET rec.c_text_t = "무전망침입"
		WHEN "fr_FR.UTF-8"
			LET rec.c_text_t = "Intrusion"
		WHEN "es_ES.utf8"
			LET rec.c_text_t = "Intrusos"
		WHEN "pt_PT.UTF-8"
			LET rec.c_text_t = "Intrusão"
		WHEN "de_DE.UTF-8"
			LET rec.c_text_t = "Eindringen"
		WHEN "ru_RU.UTF-8"
			LET rec.c_text_t = "Вторжение"
		WHEN "el_GR.UTF-8"
			LET rec.c_text_t = "Παρείσφρυση"
		OTHERWISE
			LET rec.c_text_t = rec.c_text
	END CASE

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION set_rec2( lang,nam )
	DEFINE lang,nam STRING

	LET rec.lang = lang
	LET rec.c_text = "Alarm Communications"
	CASE lang
		WHEN "zh_CN.UTF-8"
			LET rec.c_text_t = "警报通讯"
		WHEN "ko_KR.utf8"
			LET rec.c_text_t = "경보 커뮤니케이션"
		WHEN "fr_FR.UTF-8"
			LET rec.c_text_t = "Communications D'Alarme"
		WHEN "es_ES.utf8"
			LET rec.c_text_t = "Comunicación de alarmas"
		WHEN "pt_PT.UTF-8"
			LET rec.c_text_t = "Comunicações de Alarme"
		WHEN "de_DE.UTF-8"
			LET rec.c_text_t = "Warnung Kommunikationen"
		WHEN "ru_RU.UTF-8"
			LET rec.c_text_t = "Связи Сигнала тревоги"
		WHEN "el_GR.UTF-8"
			LET rec.c_text_t = "Επικοινωνίες συναγερμών"
		OTHERWISE
			LET rec.c_text_t = rec.c_text
	END CASE

END FUNCTION
--------------------------------------------------------------------------------
