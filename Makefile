# Makefile tclpd for the Makefile.pdlibbuilder build system

lib.name = tclpd


UNAME := $(shell uname -s)

ifeq ($(UNAME),Darwin)
  ldlibs = -framework Tcl
endif

ifeq ($(UNAME),Linux)
  ldlibs = -ltcl8.5
  cflags = -I/usr/include/tcl8.5 -std=c99 -DHASHTABLE_COPY_KEYS
endif

ifeq (MINGW,$(findstring MINGW,$(UNAME)))
  ldlibs = -ltcl85 "$(LIBRARY_NAME).def"
  cflags = /usr/include/tcl -std=c99 -DHASHTABLE_COPY_KEYS
endif


tclpd.class.sources = \
tclpd.c \
hashtable.c \
tcl_class.c \
tcl_loader.c \
tcl_proxyinlet.c \
tcl_typemap.c \
tcl_widgetbehavior.c \
tcl_wrap.c

datafiles = \
AUTHORS.txt \
ChangeLog.txt \
TODO.txt \
tclpd.tcl \
$(wildcard examples/*-help.pd) \
$(wildcard examples/*.tcl)


externalsdir = ../..

PDLIBBUILDER_DIR=.
include $(firstword $(wildcard $(PDLIBBUILDER_DIR)/Makefile.pdlibbuilder \
  $(externalsdir)/Makefile.pdlibbuilder))

tcl_wrap.c: tclpd.i tclpd.h Makefile
	swig -v -tcl -o tcl_wrap.c -I$(pdincludepath) tclpd.i
