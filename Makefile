.PHONY: help
help:
	@echo 'Arj, An ActiveJob queuing backend which uses ActiveRecord.'
	@echo
	@echo 'Targets:'
	@echo '  console:   Start an interactive console'
	@echo '  rubocop:   Run rubocop'
	@echo '  rspec:     Run all specs'
	@echo '  precommit: Run lint and specs'

.PHONY: console
console:
	@./script/console

.PHONY: rspec
rspec:
	@rspec

.PHONY: rubocop
rubocop:
	@rubocop

.PHONY: precommit
precommit: rspec rubocop
