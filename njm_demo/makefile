

export FGLLDPATH=$(GREDIR)/lib
GITVER=$(shell git describe --always)
GARFILE=njm_demo-$(GITVER).gar

all: src/lib/gitver.inc
	gsmake njm_demo300.4pw

src/lib/gitver.inc: 
	echo "CONSTANT GITVER=\"$(GITVER)\"" > src/lib/gitver.inc

run: all
	run.sh

clean:
	rm src/lib/gitver.inc;
	rm -f *.4pw?? \;
	find . -name \*.42? -exec rm {} \;
	find . -name \*.log -exec rm {} \;
	find . -name \*.pdf -exec rm {} \;
	find . -name \*.xml -exec rm {} \;

packit: 
	$(info Building TGZ of deployables ...)
	tar cvzf njm_demo-$(GITVER).tgz bin300 gas300 etc pics db/njm_demo.exp.tgz db/imp.sh

gar: $(GARFILE)

$(GARFILE): clean all MANIFEST gas300/gdemo.xcf
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
	gasadmin --deploy-archive $(GARFILE)
	gasadmin --enable-archive njm_demo

redeploy: undeploy deploy
	$(info Done)

