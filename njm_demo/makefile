
export FGLLDPATH=$(GREDIR)/lib

all:
	gsmake njm_demo300.4pw

run: all
	run.sh

clean:
	rm -f *.4pw?? \;
	find . -name \*.42? -exec rm {} \;
	find . -name \*.log -exec rm {} \;
	find . -name \*.pdf -exec rm {} \;
	find . -name \*.xml -exec rm {} \;

packit: 
	tar cvzf njm_demo.tgz bin300 gas300 etc pics db/njm_demo.exp.tgz db/imp.sh
