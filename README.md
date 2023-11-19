# Arj

An ActiveJob queuing backend which uses ActiveRecord. 

API docs: https://www.rubydoc.info/github/nicholasdower/arj <br>
RubyGems: https://rubygems.org/gems/arj <br>
Changelog: https://github.com/nicholasdower/arj/releases <br>
Issues: https://github.com/nicholasdower/arj/issues

For more information on ActiveJob, see:

- https://edgeguides.rubyonrails.org/active_job_basics.html
- https://www.rubydoc.info/gems/activejob

## Basic Setup

Add the following to your Gemfile:

```ruby
gem 'arj', '~> 0.0'
```

Apply a database migration:

```ruby
class CreateJobs < ActiveRecord::Migration[7.1]
  def self.up
    create_table table_name, id: :string, primary_key: :job_id do |table|
      table.string   :job_class,            null: false
      table.string   :queue_name
      table.integer  :priority
      table.text     :arguments,            null: false
      table.integer  :executions,           null: false
      table.text     :exception_executions, null: false
      table.string   :locale
      table.string   :timezone
      table.datetime :enqueued_at,          null: false
      table.datetime :scheduled_at
    end

    add_index table_name, %i[priority scheduled_at enqueued_at]
  end

  def self.down
    drop_table :jobs
  end
end
```

Create a record class:

```ruby
class Job < ActiveRecord::Base
  def self.implicit_order_column
    # Order by enqueued_at when using Job.last, Job.first, etc.
    'enqueued_at'
  end

  def to_arj
    Arj.from(self)
  end
end
```

If using Rails, configure the queue adapter via `Rails::Application`:

```ruby
class MyApplication < Rails::Application
  require 'arj'
  config.active_job.queue_adapter = :arj
end
```

If not using Rails, configure the queue adapter via `ActiveJob::Base`:

```ruby
ActiveJob::Base.queue_adapter = :arj
```

Include the `Arj` module in your job classes:

```ruby
class SampleJob < ActiveJob::Base
  include Arj
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

```ruby
Arj.count                    # Number of jobs
Arj.all                      # All jobs
Arj.last                     # Last job by database id
Arj.where(queue_name: 'foo') # Jobs in the foo queue
...
```

Optionally, query methods can be added to job classes. See the [Query Extension](#query-extension).

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

Optionally, these methods can be added to job classes. See the [Persistence Extesion](#persistence-extension).

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

### Query Extension

A module which, when included, adds class methods used to query jobs.

#### Example Usage

```ruby
class SampleJob < ActiveJob::Base
  include Arj
  include Arj::Extensions::Query
end

SampleJob.set(queue_name: 'some queue').perform_later('some arg')
job = job.where(queue_name: 'some queue').first
job.perform_now
```

Note that all query methods delegate to `.all`. This method can be overridden to create a
customized query interface. For instance, to create a job group:

```ruby
class FooBarJob < ActiveJob::Base
  include Arj
end

class FooBazJob < ActiveJob::Base
  include Arj
end

module FooJobs
  include Arj::Extensions::Query

  def self.all
    Arj.where(job_class: [FooBarJob, FooBazJob].map(&:name))
  end
end

FooBarJob.perform_later
FooBazJob.perform_later
FooJobs.available.first # Returns the first available job of type FooBarJob or FooBazJob.
```

### Persistence Extension

Provides ActiveRecord-like persistence methods for jobs:

```ruby
job.exists?
job.reload
job.save!
job.update!
job.destroy!
job.destroyed?
```

#### Example Usage

```ruby
class SampleJob < ActiveJob::Base
  include Arj
  include Arj::Extensions::Persistence
end

job = SampleJob.set(queue_name: 'some queue').perform_later('some arg')
job.queue_name = 'other queue'
job.save!
```

### Shard Extension

Adds a `shard` attribute to a job class.

#### Example Usage

```ruby
class AddShardToJobs < ActiveRecord::Migration[7.1]
  def self.up
    Arj::Extensions::Shard.migrate_up(self)
  end

  def self.down
    Arj::Extensions::Shard.migrate_down(self)
  end
end
  
class SampleJob < ActiveJob::Base
  include Arj
  include Arj::Extensions::Shard
end

SampleJob.set(shard: 'some shard').perform_later
```

### LastError Extension

Adds a `last_error` attribute to a job class.

#### Example Usage

```ruby
class AddLastErrorToJobs < ActiveRecord::Migration[7.1]
  def self.up
    Arj::Extensions::LastError.migrate_up(self)
  end

  def self.down
    Arj::Extensions::LastError.migrate_down(self)
  end
end

class SampleJob < ActiveJob::Base
  include Arj
  include Arj::Extensions::LastError

  retry_on Exception
end

job = SampleJob.perform_now
job.last_error
```

### Timeout Extension

Adds timeout support to a job class.

Example Usage

```ruby
class SampleJob < ActiveJob::Base
  include Arj
  include Arj::Extensions::Timeout

  timeout_after 1.second

  def perform
    sleep 2
  end
end

job = SampleJob.perform_later
job.perform_now
```

Optionally, the default timeout may be changed:

```ruby
Arj::Extensions::Timeout.default_timeout = 5.seconds
```

Optionally, the timeout can be customized for a job class:

```ruby
class SampleJob < ActiveJob::Base
  include Arj
  include Arj::Extensions::Timeout

  timeout_after 5.seconds
end
```

### RetainDiscarded Extension

Provides the ability to retain discarded jobs.

#### Example Usage

```ruby
class AddRetainDiscardedToJobs < ActiveRecord::Migration[7.1]
  def self.up
    Arj::Extensions::RetainDiscarded.migrate_up(self)
  end

  def self.down
    Arj::Extensions::RetainDiscarded.migrate_down(self)
  end
end

class SampleJob < ActiveJob::Base
  include Arj
  include Arj::Extensions::RetainDiscarded
end

job = SampleJob.perform_later
job.perform_now rescue nil

job.discarded?
job.discarded_at
Arj.discarded
```

## Testing

The following sample jobs are provided for use in tests:

```ruby
Arj::Test::Job
Arj::Test::JobWithShard
Arj::Test::JobWithLastError
Arj::Test::JobWithTimeout
Arj::Test::JobWithRetainDiscarded
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
job = Arj::Test::JobWithRetainDiscarded.perform_later(StandardError, 'oh, hi')
2.times { job.perform_now }
job.discarded?
job.discarded_at
```

## ActiveJob Cheatsheet

### Configuring a Queue Adapter

```ruby
# With Rails
class MyApplication < Rails::Application
  config.active_job.queue_adapter = :foo           # Instantiates FooAdapter
  config.active_job.queue_adapter = FooAdapter.new # Uses FooAdapter directly
end

# Without Rails
ActiveJob::Base.queue_adapter = :foo           # Instantiates FooAdapter
ActiveJob::Base.queue_adapter = FooAdapter.new # Uses FooAdapter directly
```

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
# Executed without enqueueing, enqueued on failure if retries configured
SampleJob.new(args).perform_now
SampleJob.perform_now(args)
ActiveJob::Base.exeucute(SampleJob.new(args).serialize)

# Executed after enqueueing
SampleJob.perform_later(args).perform_now
ActiveJob::Base.exeucute(SampleJob.perform_later(args).serialize)
```
