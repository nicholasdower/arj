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
	@echo '  install:               Run bundle install'
	@echo '  console:               Start an interactive console'
	@echo '  console-mysql:         Start an interactive console using MySQL'
	@echo '  rubocop:               Run rubocop'
	@echo '  rubocop-fix:           Run rubocop and fix auto-correctable offenses'
	@echo '  rspec:                 Run all specs'
	@echo '  rspec-mysql:           Run all specs using MySQL'
	@echo '  coverage:              Run all specs with coverage'
	@echo '  precommit:             Run lint and specs'
	@echo '  watch:                 Run lint and specs on file change'
	@echo '  doc:                   Generate documentation'
	@echo '  open-doc:              Open documentation'
	@echo '  watch-doc:             Generate documentation on file change'
	@echo '  clean:                 Remove *.gem, .yardoc/, doc/, logs/'
	@echo '  gem:                   Build a gem'
	@echo '  mysql-server:          Start MySQL'
	@echo '  mysql-client:          Start a MySQL client'

.install: Gemfile Gemfile.lock arj.gemspec
	@make install
	@touch .install

.PHONY: install
install:
	@bundle install

.PHONY: console
console:  .install
	@./script/console

.PHONY: console-mysql
console-mysql:  .install mysql-server-healthy
	@DB=mysql ./script/console

.PHONY: console-irb
console-irb:  .install
	@./script/console-irb

.PHONY: console-pry
console-pry:  .install
	@./script/console-pry

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
	@./script/rerun $(WATCH_FILES) -not -path 'lib/arj/documentation/\*' -type f -- make rspec

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
	docker compose down
	rm -rf .yardoc/
	rm -rf doc/
	rm -rf logs/

.PHONY: gem
gem: clean-gems .install
	gem build

.PHONY: mysql-logs
mysql-logs:
	mkdir -p logs
	touch logs/mysql-error.log
	touch logs/mysql-general.log
	chmod 666 logs/mysql-*.log

.PHONY: mysql-server
mysql-server:
	docker compose down
	make mysql-logs
	docker-compose up -d arj_mysql_healthy

.PHONY: mysql-server-healthy
mysql-server-healthy: mysql-logs
	./script/mysql-healthy.sh

.PHONY: mysql-client
mysql-client:
	mysql --protocol=tcp --user=root --password=root arj

.PHONY: rspec-mysql
rspec-mysql: .install mysql-server-healthy
	@DB=mysql rspec

.PHONY: remvove-containers
remove-containers:
	docker ps --format='{{.ID}}' | while read id; do docker kill "$$id"; done
	docker system prune -f
	docker volume ls -q | while read volume; do docker volume rm -f "$$volume"; done

.PHONY: remove-images
remove-images:
	docker images --format '{{ .Repository }}:{{ .Tag }}' | while read image; do docker rmi "$$image"; done
