# Server executable file:
ROOTDIR=$(shell pwd)

# ALS version
VERSION ?=
# Location of home dir for tests
export ALS_HOME=$(ROOTDIR)/testsuite

# Command to run for tests
export ALS=$(ROOTDIR)/.obj/server/ada_language_server

# Tester files
TESTER=$(ROOTDIR)/.obj/tester/tester-run
CODEC_TEST=.obj/codec_test/codec_test

GPRBUILD_FLAGS=-j0
GPRBUILD=gprbuild $(GPRBUILD_FLAGS) -XSUPERPROJECT=
GPRCLEAN=gprclean -XSUPERPROJECT=

# Installation directory
prefix ?= /usr/local
ifeq ($(DESTDIR),)
  DESTDIR=$(prefix)
endif

# Library type
LIBRARY_TYPE?=relocatable

# Build mode (dev or prod)
BUILD_MODE?=dev

# Whether to enable coverage (empty for no, any other value for yes)
COVERAGE=
COVERAGE_INSTR=gnatcov instrument --level stmt $(LIBRARY_FLAGS) \
	--dump-trigger=atexit --no-subprojects

# Target platform as nodejs reports it
ifeq ($(OS),Windows_NT)
   PLATFORM=win32
   PYTHON=python.exe
   EXE=.exe
else
   UNAME_S := $(shell uname -s)
   ifeq ($(UNAME_S),Linux)
      PLATFORM=linux
      OS=unix
   endif
   ifeq ($(UNAME_S),Darwin)
      PLATFORM=darwin
      OS=osx
   endif
   PYTHON=python3
   EXE=
endif

LIBRARY_FLAGS=-XBUILD_MODE=$(BUILD_MODE)	\
              -XOS=$(OS)			\
              -XLIBRARY_TYPE=$(LIBRARY_TYPE)	\
              -XXMLADA_BUILD=$(LIBRARY_TYPE)	\
	      -XGPR_BUILD=$(LIBRARY_TYPE)

BUILD_FLAGS=$(LIBRARY_FLAGS)

ifeq ($(COVERAGE),)
	COVERAGE_BUILD_FLAGS= $(LIBRARY_FLAGS)
else
	COVERAGE_BUILD_FLAGS= $(LIBRARY_FLAGS) \
		--implicit-with=gnatcov_rts \
		--src-subdirs=gnatcov-instr \
		-XALS_WARN_ERRORS=false \
		-XSPAWN_WARN_ERRORS=false \
		-gnatyN
endif

all: coverage-instrument
	$(GPRBUILD) -P gnat/tester.gpr -p $(BUILD_FLAGS)
	$(GPRBUILD) -d -ws -c -u -P gnat/lsp_server.gpr -p $(BUILD_FLAGS) s-memory.adb
	$(GPRBUILD) -P gnat/lsp_server.gpr -p $(COVERAGE_BUILD_FLAGS) \
		-XVERSION=$(VERSION)
	$(GPRBUILD) -P gnat/codec_test.gpr -p $(COVERAGE_BUILD_FLAGS)
	$(GPRBUILD) -P gnat/lsp_client.gpr -p $(COVERAGE_BUILD_FLAGS) \
		-XVERSION=$(VERSION)
	mkdir -p integration/vscode/ada/$(PLATFORM)
	cp -f $(ALS)$(EXE) integration/vscode/ada/$(PLATFORM)

generate:
	python scripts/generate.py

generate_io:
	python scripts/io_gen.py

coverage-instrument:
ifneq ($(COVERAGE),)
	# Remove artifacts from previous instrumentations, so that stale units that
	# are not overriden by new ones don't get in our way.
	rm -rf .obj/*/gnatcov-instr
	$(COVERAGE_INSTR) -XVERSION=$(VERSION) \
		-Pgnat/lsp_server.gpr --projects lsp_server --projects lsp
	$(COVERAGE_INSTR) -Pgnat/tester.gpr --projects lsp
	$(COVERAGE_INSTR) -Pgnat/codec_test.gpr --projects lsp
endif

install:
	gprinstall -f -P gnat/lsp_server.gpr -p -r --mode=usage \
		--prefix=$(DESTDIR) $(LIBRARY_FLAGS)
	gprinstall -f -P gnat/tester.gpr -p --prefix=$(DESTDIR) $(LIBRARY_FLAGS)
	gprinstall -f -P gnat/codec_test.gpr -p --prefix=$(DESTDIR) $(LIBRARY_FLAGS)
	gprinstall -f -P gnat/lsp_client.gpr -p -r	\
		--mode=dev				\
		--prefix=$(DESTDIR)			\
		$(LIBRARY_FLAGS)
ifneq ($(COVERAGE),)
	mkdir -p $(DESTDIR)/share/als/sids || true
	cp .obj/*/*.sid $(DESTDIR)/share/als/sids/
endif

clean:
	-$(GPRCLEAN) -P gnat/lsp.gpr $(LIBRARY_FLAGS)
	-$(GPRCLEAN) -P gnat/lsp_server.gpr $(LIBRARY_FLAGS)
	-$(GPRCLEAN) -P gnat/tester.gpr $(LIBRARY_FLAGS)
	-$(GPRCLEAN) -P gnat/codec_test.gpr $(LIBRARY_FLAGS)
	-rm -rf integration/vscode/ada/$(PLATFORM)

vscode:
ifneq ($(npm_config_offline),true)
# These commands may try to contact remote servers so if npm is configured to
# run in offline mode, don't bother running them
	cd integration/vscode/ada; LD_LIBRARY_PATH= npm install --no-audit
	cd integration/vscode/ada; LD_LIBRARY_PATH= npm run check-licenses
endif
	cd integration/vscode/ada; LD_LIBRARY_PATH= npm run compile
	@echo Now run:
	@echo code --extensionDevelopmentPath=`pwd`/integration/vscode/ada/ `pwd`

vscode-test:
	# Run the VS Code integration testsuite.
	cd integration/vscode/ada; LD_LIBRARY_PATH= npm run test

check: all
	set -e; \
        export PYTHON=$(PYTHON); \
        if [ `$(PYTHON) -c "import sys;print('e3' in sys.modules)"` = "True" ]; then\
           (cd testsuite ; sh run.sh ) ; \
        else \
           for a in testsuite/*_lsp/*/*.json; do \
              echo $$a ; \
              (cd `dirname $$a ` ; $(TESTER) `basename $$a`) ;\
           done; \
        fi
	${CODEC_TEST} < testsuite/codecs/index.txt

deploy: check
	integration/$(USER)/deploy.sh $(PLATFORM)
