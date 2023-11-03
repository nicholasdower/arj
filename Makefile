.PHONY: help
help:
	@echo 'Arj, An ActiveJob queuing backend which uses ActiveRecord.'
	@echo
	@echo 'Targets:'
	@echo '  console:   Start an interactive console'
	@echo '  rubocop:   Run rubocop'
	@echo '  rspec:     Run all specs'
	@echo '  coverage:  Run all specs with coverage'
	@echo '  precommit: Run lint and specs'

.PHONY: console
console:
	@./script/console

.PHONY: rspec
rspec:
	@rspec

.PHONY: coverage
coverage:
	@COVERAGE=1 rspec

.PHONY: rubocop
rubocop:
	@rubocop

.PHONY: precommit
precommit: rspec rubocop
