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

- [Basic Setup](#basic-setup)
- [Worker](#worker)
- [Querying](#querying)
- [Persistence](#persistence)
- [Extensions](#extensions)
  * [Query Extension](#query-extension)
  * [Persistence Extension](#persistence-extension)
  * [LastError Extension](#lasterror-extension)
  * [Shard Extension](#shard-extension)
  * [Timeout Extension](#timeout-extension)
  * [RetainDiscarded Extension](#retaindiscarded-extension)
- [Testing](#testing)
- [Migrations](#migrations)
- [ActiveJob Cheatsheet](#activejob-cheatsheet)
  * [Creating Jobs](#creating-jobs)
  * [Enqueuing Jobs](#enqueuing-jobs)
  * [Executing Jobs](#executing-jobs)

## Basic Setup

Add the following to your Gemfile:

```ruby
gem 'arj', '~> 0.0'
```

Apply a database migration (See [Migrations](#migrations) for alternatives):

```ruby
require 'arj/migration'

class CreateJobs < Arj::Migration[7.1]
  def self.up
    create_jobs_table
  end

  def self.down
    drop_table :jobs
  end
end
```

Create a record class:

```ruby
require 'active_record/base'
require 'arj'

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

Configure the queue adapter.

```ruby
require 'arj'

# If using Rails:
class MyApplication < Rails::Application
  config.active_job.queue_adapter = :arj
end

# If not using Rails:
ActiveJob::Base.queue_adapter = :arj
```

Include the `Arj` module in your job classes:

```ruby
require 'arj'

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

```
Arj.count                    # Number of jobs
Arj.all                      # All jobs
Arj.last                     # Last job by database id
Arj.where(queue_name: 'foo') # Jobs in the foo queue
...
```

Optionally, query methods can be added to job classes. See the [Query Extesion](#query-extension).

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

Adds ActiveRecord-like query methods job classes.

#### Setup

Include the `Query` extension:

```ruby
class SampleJob < ActiveJob::Base
  include Arj
  include Arj::Extensions::Query
end
```

Note that `:all` can be overridden to provide custom querying:

```ruby
class SampleJobOne < ActiveJob::Base
  include Arj
end
class SampleJobTwo < ActiveJob::Base
  include Arj
end

class SampleJobs
  include Arj::Extensions::Query

  def self.all
    Arj.where(job_class: [SampleJobOne, SampleJobTwo].map(&:name))
  end
end
```

#### Example Usage

```
SampleJob.all # All SampleJobs
SampleJobs.where(priority: 0) # Jobs of type SampleJobOne or SampleJobTwo with a priority of 0
```

### Persistence Extension

#### Setup

Include the `Persistence` extension:

```ruby
class SampleJob < ActiveJob::Base
  include Arj
  include Arj::Extensions::Persistence
end
```

#### Example Usage

```ruby
job = SampleJob.perform_later
job.update!(queue_name: 'some queue')
```

### Shard Extension

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
  include Arj
  include Arj::Extensions::Shard
end
```

#### Example Usage

```ruby
SampleJob.set(shard: 'some shard').perform_later('foo')
```

### LastError Extension

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
  include Arj
  include Arj::Extensions::LastError
end
```

#### Example Usage

```ruby
class SampleJob < ActiveJob::Base
  include Arj
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

### Timeout Extension

Adds job timeouts.

#### Setup

First, include the `Timeout` extension:

```ruby
class SampleJob < ActiveJob::Base
  include Arj
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
  include Arj
  include Arj::Extensions::Timeout

  timeout_after 5.seconds
end
```

#### Example Usage

```ruby
class SampleJob < ActiveJob::Base
  include Arj
  include Arj::Extensions::Timeout

  timeout_after 1.second

  def perform
    sleep 2
  end

  job = SampleJob.perform_later
  job.perform_now
end
```

### RetainDiscarded Extension

Provides the ability to retain discarded jobs.

#### Setup

First, apply a migration:

```ruby
class AddDiscardedAtToJobs < ActiveRecord::Migration[7.1]
  def self.up
    add_column :jobs, :discarded_at, :datetime
    change_column :jobs, :enqueued_at, :datetime, null: true
  end

  def self.down
    remove_column :jobs, :discarded_at
    change_column :jobs, :enqueued_at, :datetime, null: false
  end
end
```

Next, include the `RetainDiscarded` extension:

```ruby
class SampleJob < ActiveJob::Base
  include Arj
  include Arj::Extensions::RetainDiscarded
end
```

#### Example Usage

```ruby
class SampleJob < ActiveJob::Base
  include Arj
  include Arj::Extensions::RetainDiscarded

  def perform
    raise 'oh, hi'
  end
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

## Migrations

To create the jobs table with an `id` column as the primary key rather than `job_id`:

```ruby
class CreateJobsWithId < Arj::Migration[7.1]
  def self.up
    create_jobs_table(extensions: [:id])
  end

  def self.down
    drop_table :jobs
  end
end
```

This will result in the `provider_job_id` job attribute being populated.

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
