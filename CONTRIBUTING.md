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
  console-mysql:         Start an interactive console using MySQL
  console-postgres:      Start an interactive console using Postgres
  rubocop:               Run rubocop
  rubocop-fix:           Run rubocop and fix auto-correctable offenses
  rspec:                 Run all specs
  rspec-mysql:           Run all specs using MySQL
  coverage:              Run all specs with coverage
  precommit:             Run lint and specs
  watch:                 Run lint and specs on file change
  doc:                   Generate documentation
  open-doc:              Open documentation
  watch-doc:             Generate documentation on file change
  clean:                 Remove *.gem, .yardoc/, doc/, logs/
  gem:                   Build a gem
  mysql-server:          Start MySQL
  mysql-client:          Start a MySQL client
  postgres-server:       Start Postgres
  postgres-client:       Start a Postgres client
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

To use MySQL, [install Docker](https://docs.docker.com/get-docker), then:

- Run specs: `make rspec-mysql`
- Start a console: `make console-mysql`
- Start the server: `make mysql-server`
- Start a client: `make mysql-client`

## Using PostgreSQL

By default, SQLite is used when running tests or in the Arj console.

To use PostgreSQL, [install Docker](https://docs.docker.com/get-docker), then:

- Run specs: `make rspec-postgres`
- Start a console: `make console-postgres`
- Start the server: `make postgres-server`
- Start a client: `make postgres-client`
