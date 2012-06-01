# Makefile to install whip files
CRACKC=crackc
PREFIX=/usr/local
VERSION=$(lastword $(shell crack --version))

INSTALLDIR=${PREFIX}/lib/crack-${VERSION}/whip
libs=whip/entity.crk whip/interpreter.crk whip/sockserver.crk
tests=test/test_interpreter test/test_entity

 % : %.crk
	$(CRACKC) $<

default: $(tests) doc
doc: doc/interp_states.svg

tests: $(libs)

install:
	mkdir -p ${INSTALLDIR}
	cp whip/*.crk ${INSTALLDIR}


doc/interp_states.svg: doc/interp_states.dot
	dot -Tsvg $< -o $@


clean:
	rm $(tests)
