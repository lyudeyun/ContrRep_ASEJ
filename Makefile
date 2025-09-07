SH=$(wildcard test/scripts/*)
CSV=$(SH:test/scripts/%=results/%.csv)
DIRS=results output

.PHONY: all scalac

all: $(DIRS) $(CSV)
	# git commit -m "new benchmark results"

results:
	mkdir -p $@

output:
	mkdir -p $@

results/%.csv: test/scripts/%
	./run $* $< $@
	# git add $@

benchmarks.jar: Manifest.txt
	jar cfm $@ Manifest.txt -C bin .
clean:
	rm *.dat *.slxc *mex*
