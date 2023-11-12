# Arj

An ActiveJob queuing backend which uses ActiveRecord. 

API docs: https://www.rubydoc.info/github/nicholasdower/arj <br>
RubyGems: https://rubygems.org/gems/arj <br>
Changelog: https://github.com/nicholasdower/arj/releases <br>
Issues: https://github.com/nicholasdower/arj/issues

For more information on ActiveJob, see:

- https://edgeguides.rubyonrails.org/active_job_basics.html
- https://www.rubydoc.info/gems/activejob

## Sections

- [Setup](#setup)
- [Querying](#querying)
- [Persistence](#persistence)
- [Worker](#worker)
- [Extensions](#extensions)
  * [LastError](#lasterror)
  * [Shard](#shard)
  * [Timeout](#timeout)
  * [KeepDiscarded](#keepdiscarded)
  * [Database ID](#database-id)
- [Testing](#testing)

## Setup

Add the following to your Gemfile:

```ruby
gem 'arj', '~> 0.0'
```

Apply a database migration:

```ruby
class CreateJobs < ActiveRecord::Migration[7.1]
  def self.up
    create_table :jobs, id: :string, primary_key: :job_id do |table|
      table.string   :job_class,            null: false
      table.string   :job_id,               null: false
      table.string   :queue_name
      table.integer  :priority
      table.text     :arguments,            null: false
      table.integer  :executions,           null: false
      table.text     :exception_executions, null: false
      table.string   :locale,               null: false
      table.string   :timezone,             null: false
      table.datetime :enqueued_at,          null: false
      table.datetime :scheduled_at
    end
    add_index :jobs, [ :priority, :scheduled_at, :enqueued_at ]
  end

  def self.down
    drop_table :jobs
  end
end
```

**Note**: The default table schema does not include an ID column. A schema with an ID column can be found [here](#database-id).

Configure the queue adapter.

If using Rails:

```ruby
class MyApplication < Rails::Application
  config.active_job.queue_adapter = :arj
end
```

If not using Rails:

```ruby
ActiveJob::Base.queue_adapter = :arj
```

Include the `Arj::Base` module:

```ruby
class SampleJob < ActiveJob::Base
  include Arj::Base
end
```

## Querying

The `Arj` module exposes query methods which can be used to find jobs:

```ruby
Arj.queue('foo')             # Jobs in the foo queue
Arj.failing                  # Failing jobs
Arj.executable               # Executable jobs
Arj.todo                     # Executable jobs in order
```

It also exposes ActiveRecord query methods:

```
Arj.count                    # Number of jobs
Arj.all                      # All jobs
Arj.last                     # Last job by database id
Arj.where(queue_name: 'foo') # Jobs in the foo queue
...
```

Optionally, query methods can also be added to job classes:

```ruby
class SampleJob < ActiveJob::Base
  include Arj::Base
  include Arj::Query
end

SampleJob.all # All SampleJobs
```

`:all` can be overridden to provide custom querying:

```ruby
class SampleJobOne < ActiveJob::Base
  include Arj::Base
end
class SampleJobTwo < ActiveJob::Base
  include Arj::Base
end

class SampleJobs
  include Arj::Query

  def self.all
    Arj.where(job_class: [SampleJobOne, SampleJobTwo].map(&:name))
  end
end

SampleJobs.where(priority: 0) # Jobs of type SampleJobOne or SampleJobTwo with a priority of 0
```

## Persistence

The `Arj` module exposes ActiveRecord-like persistence methods. For example:

```ruby
Arj.exists?(job)
Arj.reload(job)
Arj.save!(job)
Arj.update!(job, attributes)
Arj.destroy!(job)
Arj.destroyed?(job)
```

Optionally, these methods can be added to job classes:

```ruby
class SampleJob < ActiveJob::Base
  include Arj::Base
  include Arj::Persistence
end
```

Example usage:

```ruby
job = SampleJob.perform_later
job.update!(queue_name: 'some queue')
```

## Worker

To execute all available jobs:

```ruby
Arj::Worker.new.work_off
```

To start a worker which will execute jobs as they become available:

```ruby
Arj::Worker.new.start
```

To start a worker with custom criteria:

```ruby
Arj::Worker.new(description: 'Arj::Worker(foo)', source: -> { Arj.queue('foo').todo }).start
```

## Extensions

### Shard

Adds a +shard+ attribute to jobs.

#### Setup

First, apply a migration:

```ruby
class AddShardToJobs < ActiveRecord::Migration[7.1]
  def change
    add_column :jobs, :shard, :string
  end
end
```

Next, include the `Shard` extension:

```ruby
class SampleJob < ActiveJob::Base
  include Arj::Base
  include Arj::Extensions::Shard
end
```

#### Example Usage

```ruby
SampleJob.set(shard: 'some shard').perform_later('foo')
```

### LastError

Adds a +last_error+ attribute to jobs which will contain the stacktrace of the last error encountered during execution.

#### Setup

First, apply a migration:

```ruby
class AddLastErrorToJobs < ActiveRecord::Migration[7.1]
  def change
    add_column :jobs, :last_error, :text
  end
end
```

Next, include the `LastError` extension:

```ruby
class SampleJob < ActiveJob::Base
  include Arj::Base
  include Arj::Extensions::LastError
end
```

#### Example Usage

```ruby
class SampleJob < ActiveJob::Base
  include Arj::Base
  include Arj::Extensions::LastError

  retry_on Exception

  def perform
    raise 'oh, hi'
  end
end

job = SampleJob.perform_later
job.perform_now
puts job.last_error
```

### Timeout

Adds job timeouts.

#### Setup

First, include the `Timeout` extension:

```ruby
class SampleJob < ActiveJob::Base
  include Arj::Base
  include Arj::Extensions::Timeout

  def perform
    sleep 10
  end
end
```

Optionally, override the default timeout:

```ruby
Arj::Extensions::Timeout.default_timeout = 5.seconds
```

Optionally, override the default timeout for a job class:

```ruby
class SampleJob < ActiveJob::Base
  include Arj::Base
  include Arj::Extensions::Timeout

  timeout_after 5.seconds
end
```

#### Example Usage

```ruby
class SampleJob < ActiveJob::Base
  include Arj::Base
  include Arj::Extensions::Timeout

  timeout_after 1.second

  def perform
    sleep 2
  end

  job = SampleJob.perform_later
  job.perform_now
end
```

### KeepDiscarded

### Database ID

To create the jobs table with an id column, use this alternative migration:

```ruby
class CreateJobs < ActiveRecord::Migration[7.1]
  def self.up
    create_table :jobs do |table|
      table.string   :job_id,               null: false
      table.string   :job_class,            null: false
      table.string   :job_id,               null: false
      table.string   :queue_name
      table.integer  :priority
      table.text     :arguments,            null: false
      table.integer  :executions,           null: false
      table.text     :exception_executions, null: false
      table.string   :locale,               null: false
      table.string   :timezone,             null: false
      table.datetime :enqueued_at,          null: false
      table.datetime :scheduled_at
    end
    add_index :jobs, :job_id, unique: true
    add_index :jobs, [ :priority, :scheduled_at, :enqueued_at ]
  end

  def self.down
    drop_table :jobs
  end
end
```

This will result in the `provider_job_id` job attribute being populated.

## Testing

The following sample jobs are provided for use in tests:

```ruby
Arj::Test::Job
Arj::Test::JobWithShard
Arj::Test::JobWithLastError
Arj::Test::JobWithTimeout
Arj::Test::JobWithKeepDiscarded
```

To test job failures:

```ruby
job = Arj::Test::Job.perform_later(StandardError)
job.perform_now
```

To test retries:

```ruby
job = Arj::Test::Job.perform_later(Arj::Test::Error)
job.perform_now
```

To test timeouts:

```ruby
job = Arj::Test::JobWithTimeout.perform_later(-> { sleep 2 })
job.perform_now
```

To test retention on discard:

```ruby
job = Arj::Test::JobWithKeepDiscarded.perform_later(StandardError, 'oh, hi')
2.times { job.perform_now }
job.discarded?
job.discarded_at
```

## ActiveJob Cheatsheet

### Creating Jobs

```ruby
job = SampleJob.new                 # Created without args, not enqueued
job = SampleJob.new(args)           # Created with args, not enqueued

job = SampleJob.perform_later       # Enqueued without args
job = SampleJob.perform_later(args) # Enqueued with args

SampleJob.perform_now               # Created without args, not enqueued unless retried
SampleJob.perform_now(args)         # Created with args, ot enqueued unless retried
```

### Enqueueing Jobs

```ruby
SampleJob.new(args).enqueue                    # Enqueued without options
SampleJob.new(args).enqueue(options)           # Enqueued with options

SampleJob.perform_later(args)                  # Enqueued without options
SampleJob.options(options).perform_later(args) # Enqueued with options

SampleJob.perform_now(args)                    # Enqueued on failure if retries configured

ActiveJob.perform_all_later(                   # All enqueued without options
  SampleJob.new, SampleJob.new
)
ActiveJob.perform_all_later(                   # All enqueued with options
  SampleJob.new, SampleJob.new, options:
)

SampleJob                                      # All enqueued without options
  .set(options)
  .perform_all_later(
    SampleJob.new, SampleJob.new
  )
SampleJob                                      # All enqueued with options
  .set(options)
  .perform_all_later(
    SampleJob.new, SampleJob.new, options:
  )
```

### Executing Jobs

```ruby
# Performed without enqueueing, enqueued on failure if retries configured
job = SampleJob.new
SampleJob.new.perform_now
SampleJob.new.execute
ActiveJob::Base.exeucute(job.serialize)

# Performed after enqueueing
job = SampleJob.perform_later
job.perform_now
ActiveJob::Base.exeucute(job.serialize)
```
