PLUGIN_NAME:=$(basename $(notdir $(abspath .)))
SPEC_DIR:=./spec/lua/${PLUGIN_NAME}

test: $(SPEC_DIR)/cgi-bin/git-http-backend
	vusted --shuffle
.PHONY: test

$(SPEC_DIR)/cgi-bin/git-http-backend:
	cp $(shell git --exec-path)/git-http-backend ./$@

doc:
	rm -f ./doc/${PLUGIN_NAME}.nvim.txt ./README.md
	PLUGIN_NAME=${PLUGIN_NAME} nvim --headless -i NONE -n +"lua dofile('${SPEC_DIR}/doc.lua')" +"quitall!"
	cat ./doc/${PLUGIN_NAME}.nvim.txt ./README.md
.PHONY: doc

vendor:
	nvim --headless -i NONE -n +"lua require('vendorlib').install('${PLUGIN_NAME}', '${SPEC_DIR}/vendorlib.lua')" +"quitall!"
.PHONY: vendor
