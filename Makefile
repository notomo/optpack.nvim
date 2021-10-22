test: spec/lua/optpack/cgi-bin/git-http-backend
	vusted --shuffle
.PHONY: test

spec/lua/optpack/cgi-bin/git-http-backend:
	mkdir -p spec/lua/optpack/cgi-bin
	cp $(shell git --exec-path)/git-http-backend ./$@
