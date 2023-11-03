# Contributing

## Setup

1. Install Ruby 3.2.2.

## Run specs

```shell
make rspec
```

## Run rubocop

```shell
make rubocop
```

## Start an interactive console

```shell
make console
> Arj::TestJob.perform_later
> Arj::TestJob.set(wait: 5.minutes).perform_later
> Arj::TestJobWithRetry.perform_later(error: Arj::TestError)
> Arj.next.perform_now
> reset
```
