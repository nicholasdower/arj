INSTALL_FILES := Gemfile Gemfile.lock arj.gemspec
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
	@echo '  install:     Run bundle install'
	@echo '  console:     Start an interactive console'
	@echo '  rubocop:     Run rubocop'
	@echo '  rubocop-fix: Run rubocop and fix auto-correctable offenses'
	@echo '  rspec:       Run all specs'
	@echo '  coverage:    Run all specs with coverage'
	@echo '  precommit:   Run lint and specs'
	@echo '  watch:       Run lint and specs on file change'
	@echo '  yard:        Generate documentation'
	@echo '  yard-open:   Generate and open documentation'
	@echo '  yard-watch:  Generate and open documentation, regenerate on change'
	@echo '  clean:       Remove *.gem, .yardoc/, doc/'

.install: Gemfile Gemfile.lock arj.gemspec
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

.PHONY: rubocop-fix
rubocop-fix: .install
	@rubocop -A

.PHONY: precommit
precommit: .install
	@rspec --format progress
	@rubocop

.PHONY: watch
watch: .install
	@./script/rerun $(WATCH_FILES) -type f -- make precommit

.PHONY: yard
yard: .install
	@yard 

.PHONY: yard-open
yard-open: yard
	@if [[ `which open` ]]; then open ./doc/Arj.html; fi

.PHONY: yard-watch
yard-watch:
	@if [[ `which open` ]]; then open ./doc/Arj.html; fi
	@./script/rerun $(WATCH_FILES) -type f -- make yard

.PHONY: clean
clean:
	rm -rf *.gem
	rm -rf .yardoc/
	rm -rf doc/
