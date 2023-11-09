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
	@echo 'Arj. An ActiveJob queuing backend which uses ActiveRecord.'
	@echo
	@echo 'Targets:'
	@echo '  install:     Run bundle install'
	@echo '  console:     Start an interactive console'
	@echo '  rubocop:     Run rubocop'
	@echo '  rubocop-fix: Run rubocop and fix auto-correctable offenses'
	@echo '  rspec:       Run all specs'
	@echo '  coverage:    Run all specs with coverage'
	@echo '  precommit:   Run lint and specs'
	@echo '  watch:       Run lint, specs and generate documentation on file change'
	@echo '  doc:         Generate documentation'
	@echo '  open-doc:    Open documentation'
	@echo '  watch-doc:   Generate documentation on file change'
	@echo '  clean:       Remove *.gem, .yardoc/, doc/'
	@echo '  gem:         Build a gem'

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
	@COVERAGE=1 rspec --format progress
	@rubocop
	@yard

.PHONY: watch
watch: .install
	@./script/rerun $(WATCH_FILES) -type f -- make precommit

.PHONY: doc
doc: .install
	@ruby -r ./lib/arj/documentation/generator.rb -e Arj::Documentation::Generator.generate_all
	@yard

.PHONY: open-doc
open-doc:
	@if [[ `which open` ]]; then open ./doc/Arj.html; fi

.PHONY: watch-doc
watch-doc:
	@./script/rerun $(WATCH_FILES) README.md -not -path 'lib/arj/documentation/\*' -type f -- make doc

.PHONY: clean-gems
clean-gems:
	rm -rf *.gem

.PHONY: clean
clean: clean-gems
	rm -rf .yardoc/
	rm -rf doc/

.PHONY: gem
gem: clean-gems .install
	gem build
