version:=$(shell swipl -q -s pack -g 'version(V),writeln(V)' -t halt)
packfile=dict_schema-$(version).tgz
remote=packs@packs.rlaanemets.com:/usr/share/nginx/packs.rlaanemets.com/dict-schema

test:
	swipl -s tests/tests -g run_tests -t halt

package: test
	tar cvzf $(packfile) prolog tests pack.pl README.md

doc:
	swipl -q -t 'doc_save(prolog, [doc_root(doc),format(html),title(dict_schema),if(true),recursive(false)])'

upload: package doc
	scp $(packfile) $(remote)/$(packfile)
	rsync -avz -e ssh doc $(remote)

.PHONY: test package upload doc all
