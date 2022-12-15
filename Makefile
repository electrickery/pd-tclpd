# Makefile tclpd for the Makefile.pdlibbuilder build system

lib.name = tclpd


UNAME := $(shell uname -s)

ifeq ($(UNAME),Darwin)
  ldlibs = -framework Tcl
endif

ifeq ($(UNAME),Linux)
  ldlibs = -ltcl8.6
  cflags = -I/usr/include/tcl8.6 -std=c99 -DHASHTABLE_COPY_KEYS
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
$(wildcard examples/*.tcl) \
examples/bitmap-madness.pd

# hack to get a proper default target
all:

tcl_wrap.c: tclpd.i tclpd.h Makefile
	swig -v -tcl -o tcl_wrap.c -I$(PDDIR)/src tclpd.i

PDLIBBUILDER_DIR=pd-lib-builder/
include $(PDLIBBUILDER_DIR)/Makefile.pdlibbuilder
