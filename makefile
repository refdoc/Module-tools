MODULENAME=

USFM=./usfm/*SFM
OSIS=$(MODULENAME).osis.xml
FIXED=$(OSIS).fixed.xml
MODULE=./modules/texts/ztext/$(MODULENAME)
all: $(MODULE)
	
$(OSIS):
	./bin/usfm2osis.py $(MODULENAME) -x $(USFM)

$(FIXED): $(OSIS)
	./xreffix.pl $(OSIS)


$(MODULE): $(FIXED)
	osis2mod $(MODULE) $(FIXED) -z z


clean:
	rm *osis.xml *fixed.xml 
	rm ../modules/texts/ztext/$(MODULENAME)/*
	         
 
publish: all
	cp $(MODULENAME).conf ../mods.d/
	zip -r $(MODULENAME).zip ../mods.d ../modules
#	git add ../mods.d/$(MODULENAME).conf ../modules/texts/ztext/* $(MODULENAME).osis.xml.fixed.xml
#	git commit -m "updated publication files"
#	git push crosswire

setup:
	mkdir -p remotescripts usfm osis mods.d modules/texts/ztext/$(MODULENAME)

	wget -P remotescripts http://www.crosswire.org/svn/sword-tools/trunk/modules/crossreferences/xreffix.pl
	wget -P remotescripts http://www.crosswire.org/svn/sword-tools/trunk/modules/conf/confmaker.pl

	
	chmod +x scripts/*
	
	

help:
	$(info available targets are 'all', 'clean', 'publish')	