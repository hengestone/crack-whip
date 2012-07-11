# Makefile to install whip files
CRACKC=crackc
PREFIX=/usr/local
VERSION=$(lastword $(shell crack --version))

INSTALLDIR=${PREFIX}/lib/crack-${VERSION}/whip
libs=whip/entity.crk whip/interpreter.crk whip/sockserver.crk
serializer_libs=whip/serializer.crk whip/xdr_serializer.crk

tests=test/test_interpreter test/test_entity test/test_serialize test/test_generator

default: $(tests) doc
doc: doc/interp_states.svg

test/test_serialize: $(serializer_libs)
test/test_interpreter: $(libs)
test/test_entity: whip/entity.crk
test/test_generator: whip/generator.crk $(serializer_libs)

 % : %.crk
	$(CRACKC) $<


install:
	mkdir -p ${INSTALLDIR}
	cp whip/*.crk ${INSTALLDIR}


doc/interp_states.svg: doc/interp_states.dot
	dot -Tsvg $< -o $@


clean:
	rm -fv $(tests) test/*.o test/*~ whip/*.o doc/*~
