

export FGLLDPATH=$(GREDIR)/lib
GITVER=$(shell git describe --always)
GARNAME=njm_demo
GARFILE=$(GARNAME).gar

all: src/lib/gitver.inc app 

app:
	gsmake njm_demo300.4pw

src/lib/gitver.inc: 
	echo "CONSTANT GITVER=\"$(GITVER)\"" > src/lib/gitver.inc

run: all
	run.sh menu.42r

run2: all
	run.sh webOE3.42r

clean:
	rm -f *.gar;
	rm -f *.tgz;
	rm -f src/lib/gitver.inc;
	rm -f *.4pw??;
	rm -f gbc/njm_gbc.tgz;
	find . -name \*.42? -exec rm {} \;
	find . -name \*.log -exec rm {} \;
	find . -name \*.pdf -exec rm {} \;
	find . -name \*.xml -exec rm {} \;

packit: gbc/njm_gbc.tgz
	$(info Building TGZ of deployables ...)
	tar cvzf njm_demo-$(GITVER).tgz bin300 gas300 etc pics db/njm_demo.exp.tgz db/imp.sh gbc/njm_gbc.tgz

gbc/njm_gbc.tgz:
	cd gbc ; ./packit.sh

gar: $(GARFILE)

$(GARFILE): clean all MANIFEST gas300/gdemo.xcf
	$(info Building Genero Archive ...)
	@zip -qr $(GARNAME)-$(GITVER).gar MANIFEST gas300/g*.xcf bin300/* etc/* pics/*
	ln -s $(GARNAME)-$(GITVER).gar $(GARFILE)
	$(info Done)
	


# NOTE: can't use fglgar because it assumes a sloppy folder layout where 
# everything is dumped into a single folder!! ( including the MANIFEST file )
#	fglgar --gar --input-source ./messy

undeploy:
	gasadmin --disable-archive $(GARNAME)
	gasadmin --undeploy-archive $(GARNAME)

deploy: $(GARFILE) packit
	gasadmin --deploy-archive $(GARFILE)
	gasadmin --enable-archive $(GARNAME)

redeploy: undeploy deploy
	$(info Done)

