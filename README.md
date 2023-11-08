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
    create_table :jobs do |table|
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

      table.timestamps
    end
  end

  def self.down
    drop_table :jobs
  end
end
```

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

## Querying

The `Arj` module exposes ActiveRecord query methods which can be used to find jobs. For example:

```ruby
Arj.count                    # Number of jobs
Arj.all                      # All jobs
Arj.last                     # Last job by database id
Arj.where(queue_name: 'foo') # Jobs in the foo queue
```

Optionally, query methods can also be added to job classes:

```ruby
class SampleJob < ActiveJob::Base
  include Arj::Query
end

SampleJob.all # All SampleJobs
```

`:all` can be overridden to provide custom querying:

```ruby
class SampleJobOne < ActiveJob::Base; end
class SampleJobTwo < ActiveJob::Base; end

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
  include Arj::Persistence
end
```

And used like:

```ruby
job = SampleJob.perform_later
job.update!(queue_name: 'some queue')
```

## Workers

Execute all availble jobs using a worker:

```ruby
Arj::Worker.new.work_off
```

Start a worker which will execute jobs as they become available:

```ruby
Arj::Worker.new.start
```

Start a job with custom criteria:

```ruby
Arj::Worker.new(description: 'Arj::Worker(first)', source: -> { Arj.first }).start
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
  include Arj::Extensions::LastError
end
```

#### Example Usage

```ruby
class SampleJob < ActiveJob::Base
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
  include Arj::Extensions::Timeout

  timeout_after(5.seconds)
end
```

#### Example Usage

```ruby
class SampleJob < ActiveJob::Base
  include Arj::Extensions::Timeout

  timeout_after(1.second)

  def perform
    sleep 2
  end

  job = SampleJob.perform_later
  job.perform_now
end
```

## Testing

The following sample jobs are provided for use in tests:

```ruby
Arj::Test::Job
Arj::Test::JobWithShard
Arj::Test::JobWithLastError
Arj::Test::JobWithTimeout
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
