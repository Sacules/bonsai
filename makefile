root ?= build
PREFIX = $(root)

bonsai: FORCE
.PHONY: FORCE
FORCE:

all: bonsai

bonsai:
	:> bonsai
	@echo '[*] collating sources into executable...'
	find src -type f | while read -r file ; do \
		cat $$file >> bonsai ; \
	done
	echo 'main "$$@"' >> bonsai
	@echo '[*] removing comments and blank lines from executable...'
	# note: lines prefixed by '#_' remain blank lines
	#       '##' are preserved as comments
	sed -e 's:## :_TEMP_:g' \
	    -e 's:^\s*# .*$$::g' \
	    -e 's:_TEMP_:## :g' \
	    -e '/^$$/d' \
	    -e 's:#_::g' bonsai > bonsai.tmp
	echo '#!/bin/sh -e' > bonsai
	cat bonsai.tmp >> bonsai
	rm bonsai.tmp
	chmod +x bonsai

install:
	install -Dm755 bonsai ${PREFIX}/src/bonsai
	cp -rf ports ${PREFIX}/src
	if [ ! -f ${PREFIX}/src/bonsai.rc ] ; then \
		root="$(root)" ./bonsai --skeleton ; \
	fi

clean:
	rm -f bonsai

uninstall:
	@echo "Unsafe. Please do this manually."

ignores = -e SC1090 -e SC2154 -e SC2068 -e SC2046 -e SC2086 -e SC2119 -e SC2120
# ----- ShellCheck Explanations --------
# SC1090: "at run-time file sourcing" ie '. $pkgfile'
#         We use this to import each package's variables.
# SC2154: "var referenced but not assigned"
#		  All of the config variables are set
#		  at run time when the config is sourced.
# SC2068: for i in $@ ; do : ; done --- loop array splitting
#         This is always done intentionally.
# SC2046 + 2086: Word splitting
#		  This one is the hardest to ignore,
#		  but it is the one most carefully managed.
#		  When words are split, they are done so intentionally.
# SC2119 + SC2120: arguments supplied but not forwarded/used
#		  Shellcheck cannot see arguments given from pkgfiles.
test: bonsai
	shellcheck -s sh -x -a bonsai $(ignores)
	@echo "All checks passed!"
