INSTALL_FILES := Gemfile Gemfile.lock .release-version arj.gemspec
WATCH_FILES := $(INSTALL_FILES) .rubocop.yml lib script spec

.PHONY: help
help:
	@echo '                    _ '
	@echo '     /\            |_|'
	@echo '    /  \     _ __   _ '
	@echo '   / /\ \   |  __| | |'
	@echo '  / ____ \  | |    | |'
	@echo ' /_/    \_\ |_|   _/ |'
	@echo '                 |__/ '
	@echo 'Arj, An ActiveJob queuing backend which uses ActiveRecord.'
	@echo
	@echo 'Targets:'
	@echo '  install:   Run bundle install'
	@echo '  console:   Start an interactive console'
	@echo '  rubocop:   Run rubocop'
	@echo '  rspec:     Run all specs'
	@echo '  coverage:  Run all specs with coverage'
	@echo '  precommit: Run lint and specs'
	@echo '  watch:     Run lint and specs on file change'

.install: Gemfile Gemfile.lock .release-version arj.gemspec
	@make install
	@touch .install

.PHONY: install
install:
	@bundle install

.PHONY: console
console:  .install
	@./script/console

.PHONY: rspec
rspec: .install
	@rspec

.PHONY: coverage
coverage: .install
	@COVERAGE=1 rspec

.PHONY: rubocop
rubocop: .install
	@rubocop

.PHONY: precommit
precommit: .install
	@rspec --format progress
	@rubocop

.PHONY: watch
watch: .install
	@./script/rerun $(WATCH_FILES) -type f -- make precommit
