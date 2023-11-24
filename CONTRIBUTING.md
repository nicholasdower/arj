# Contributing

Install Ruby >= 2.7.0, then run `make help`:

```
                    _
     /\            |_|
    /  \     _ __   _
   / /\ \   |  __| | |
  / ____ \  | |    | |
 /_/    \_\ |_|   _/ |
                 |__/
Arj. An ActiveJob queuing backend which uses ActiveRecord.

Targets:
  install:               Run bundle install
  console:               Start an interactive console
  rubocop:               Run rubocop
  rubocop-fix:           Run rubocop and fix auto-correctable offenses
  rspec:                 Run all specs
  coverage:              Run all specs with coverage
  precommit:             Run lint and specs
  watch:                 Run lint and specs on file change
  doc:                   Generate documentation
  open-doc:              Open documentation
  watch-doc:             Generate documentation on file change
  clean:                 Remove *.gem, .yardoc/, doc/, logs/
  gem:                   Build a gem
  mysql-server:          Start MySQL
  mysql-server-detached: Start MySQL in the background
  mysql-client:          Start a MySQL client
  stop:                  Stop MySQL
```

## Logs

To see database or Rails logs when running tests:

```shell
LEVEL=0 make rspec
```

Or in the Arj console:

```shell
LEVEL=0 make console
```

## Using MySQL

By default, SQLite is used when running tests or in the Arj console.

To use MySQL:

1. Install Docker: https://docs.docker.com/get-docker
2. Run specs: `make rspec-mysql`
3. Start a console: `make console-mysql`
