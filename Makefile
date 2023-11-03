.PHONY: help
help:
	@echo 'Arj'

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
