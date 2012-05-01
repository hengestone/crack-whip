# Makefile to install whip files
PREFIX=/usr/local
VERSION=0.6
INSTALLDIR=${PREFIX}/lib/crack-${VERSION}/whip

install:
	mkdir -p ${INSTALLDIR}
	cp whip/*.crk ${INSTALLDIR}
