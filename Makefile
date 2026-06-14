include spec/.shared/neovim-plugin.mk

spec/.shared/neovim-plugin.mk:
	git clone https://github.com/notomo/workflow.git --depth 1 spec/.shared

$(SPEC_DIR)/cgi-bin/git-http-backend:
	cp $(shell git --exec-path)/git-http-backend ./$@

deps: $(SPEC_DIR)/cgi-bin/git-http-backend

# The install/update specs run a git http server on a fixed port and share git
# fixture dirs, so they cannot run in parallel isolated workers.
test: FORCE deps
	$(MAKE) requireall
	$(NTF) --jobs=1 --shuffle ${SPEC_DIR}
