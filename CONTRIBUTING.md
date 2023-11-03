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
```

Enqueue a job:

```ruby
> job = Arj::TestJob.perform_later
```

Enqueue a job which retries:

```ruby
> Arj::TestJobWithRetry.perform_later(error: Arj::TestJobWithRetry::Error)
```

Find jobs:

```ruby
> Arj.all
```

Run a job:

```ruby
> job.perform_now
```

Destroy all jobs:

```ruby
> Arj.destroy_all
```

Reset the console:

```shell
> reset
```
