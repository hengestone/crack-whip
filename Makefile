# Makefile to install whip files
ifndef CRACKC
  CRACKC=crackc
 endif

ifndef RAGEL
  RAGEL=ragel
endif

PREFIX=$(shell ldd `which crack` | grep -e 'libCrackLang'| sed  's/.*libCrackLang.* => \(.*\)\/lib\/libCrackLang.*/\1/g')
VERSION=$(lastword $(shell crack --version))

INSTALLDIR=${PREFIX}/lib/crack-${VERSION}/whip
libs=whip/entity.crk whip/interpreter.crk whip/sockserver.crk
serializer_libs=whip/serializer.crk whip/xdr_serializer.crk \
                whip/json_serializer.crk

tests=test/test_interpreter test/test_entity test/test_serialize \
      test/test_generator test/test_ruby_generator \
      test/ruby_generated.rb test/crack_generated.crk \
      test/crack_generated_json.crk \
      test/test_msginterpreter test/test_msgclient

default: $(tests) bin/whipclass
doc: doc/interp_states.svg

test/test_serialize: $(serializer_libs)
test/test_interpreter: $(libs)
test/test_entity: whip/entity.crk
test/test_generator: whip/utils/generator.crk $(serializer_libs) \
                     test/test_generator.crk whip/utils/crack_generator.crk

test/test_ruby_generator: whip/utils/generator.crk $(serializer_libs) \
                     test/test_ruby_generator.crk whip/utils/ruby_generator.crk
whip/utils/idl_parser.crk: ragel/idl_parser.rl
	$(RAGEL) -K -F0 $< -o $@

test/ruby_generated.rb: test/test_ruby_generator
	$< > $@

test/crack_generated.crk: test/test_generator
	$< > $@

test/crack_generated_json.crk: bin/whipclass 
	$< --idl=test/test_message.whipdl --lang=crack > $@

test/test_msginterpreter: test/test_msginterpreter.crk whip/msgserver.crk \
                          $(libs) $(serializer_libs)

test/test_msgclient: test/test_msgclient.crk whip/msgserver.crk \
                          $(libs) $(serializer_libs)


bin/whipclass: src/whipclass.crk whip/utils/idl_parser.crk \
               whip/utils/generator.crk whip/utils/crack_generator.crk \
               whip/utils/ruby_generator.crk $(serializer_libs)
	$(CRACKC) -l $(PREFIX)/lib src/whipclass.crk
	mv src/whipclass $@

 % : %.crk
	$(CRACKC) -l $(PREFIX)/lib $<


install:
	mkdir -p ${INSTALLDIR}
	install -C -D -d whip ${INSTALLDIR}


doc/interp_states.svg: doc/interp_states.dot
	dot -Tsvg $< -o $@


clean:
	rm -fv $(tests) test/*.o test/*~ whip/*.o doc/*~ bin/whipclass
