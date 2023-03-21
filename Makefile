include spec/.shared/neovim-plugin.mk

spec/.shared/neovim-plugin.mk:
	git clone https://github.com/notomo/workflow.git --depth 1 spec/.shared

$(SPEC_DIR)/cgi-bin/git-http-backend:
	cp $(shell git --exec-path)/git-http-backend ./$@

deps: $(SPEC_DIR)/cgi-bin/git-http-backend
