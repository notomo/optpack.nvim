test: spec/lua/optpack/cgi-bin/git-http-backend
	vusted --shuffle
.PHONY: test

spec/lua/optpack/cgi-bin/git-http-backend:
	cp $(shell git --exec-path)/git-http-backend ./$@

doc:
	rm -f ./doc/optpack.nvim.txt ./README.md
	nvim --headless -i NONE -n +"lua dofile('./spec/lua/optpack/doc.lua')" +"quitall!"
	cat ./doc/optpack.nvim.txt ./README.md
.PHONY: doc
