
&define DEF_DATA_AR \
		cf1 CHAR(50), \
		if1 INTEGER, \
		nf1 DECIMAL(10,2), \
		df1 DATE, \
		cf2 CHAR(50), \
		if2 INTEGER, \
		nf2 DECIMAL(10,2), \
		df2 DATE, \
		cf3 CHAR(50), \
		if3 INTEGER, \
		nf3 DECIMAL(10,2), \
		df3 DATE, \
		cf4 CHAR(50), \
		if4 INTEGER, \
		nf4 DECIMAL(10,2), \
		df4 DATE, \
		cf5 CHAR(50), \
		if5 INTEGER, \
		nf5 DECIMAL(10,2), \
		df5 DATE, \
		cf6 CHAR(50), \
		if6 INTEGER, \
		nf6 DECIMAL(10,2), \
		df6 DATE, \
		cf7 CHAR(50), \
		if7 INTEGER, \
		nf7 DECIMAL(10,2), \
		df7 DATE, \
		cf8 CHAR(50), \
		if8 INTEGER, \
		nf8 DECIMAL(10,2), \
		df8 DATE, \
		cf9 CHAR(50), \
		if9 INTEGER, \
		nf9 DECIMAL(10,2), \
		df9 DATE, \
		cf10 CHAR(50), \
		if10 INTEGER, \
		nf10 DECIMAL(10,2), \
		df10 DATE, \
		cf11 CHAR(50), \
		if11 INTEGER, \
		nf11 DECIMAL(10,2), \
		df11 DATE, \
		cf12 CHAR(50), \
		if12 INTEGER, \
		nf12 DECIMAL(10,2), \
		df12 DATE

&define INTO_DATA_AR( recs ) \
		m_data_ar[recs].cf1, \
		m_data_ar[recs].cf2, \
		m_data_ar[recs].cf3, \
		m_data_ar[recs].cf4, \
		m_data_ar[recs].cf5, \
		m_data_ar[recs].cf6, \
		m_data_ar[recs].cf7, \
		m_data_ar[recs].cf8, \
		m_data_ar[recs].cf9, \
		m_data_ar[recs].cf10, \
		m_data_ar[recs].cf11, \
		m_data_ar[recs].cf12
