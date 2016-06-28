
GARFILE=njm_demo.gar

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
	$(info Building TGZ of deployables ...)
	tar cvzf njm_demo.tgz bin300 gas300 etc pics db/njm_demo.exp.tgz db/imp.sh

$(GARFILE): all MANIFEST gas300/gdemo.xcf
	$(info Building Genero Archive ...)
	@zip -qr  $(GARFILE) MANIFEST gas300/g*.xcf bin300/* etc/* pics/*
	$(info Done)


# NOTE: can't use fglgar because it assumes a sloppy folder layout where 
# everything is dumped into a single folder!! ( including the MANIFEST file )
#	fglgar --gar --input-source ./messy

undeploy:
	gasadmin --disable-archive njm_demo
	gasadmin --undeploy-archive njm_demo

deploy: njm_demo.gar
	gasadmin --deploy-archive njm_demo.gar
	gasadmin --enable-archive njm_demo

