FILES := library.dylan \
	 interface.dylan \
	 transform.dylan \
	 printing.dylan \
	 collect.dylan \
	 latin1-entities.dylan \
	 productions.dylan

libxml-parser.a: $(FILES)
	d2c -L ../anaphora -L ../meta -L ../multimap xml-parser.lid

clean:
	rm *.o *.c *~ cc-*.mak *.a *.du

tarball:
	tar cvf xml.tar $(FILES) Makefile xml-parser.lid; gzip xml.tar
