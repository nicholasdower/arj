# Arj

An ActiveJob queuing backend which uses ActiveRecord. 

For more information on ActiveJob, see:

- https://edgeguides.rubyonrails.org/active_job_basics.html
- https://www.rubydoc.info/gems/activejob

## Sections

- [Setup](#setup)
- [Querying](#querying)
- [Persistence](#persistence)
- [Worker](#worker)
- [Customization Examples](#customization-examples)
  * [Adding a shard column](#adding-a-shard-column)
  * [Adding a last error column](#adding-a-last-error-column)
- [Testing](#testing)

## Setup

Add the following to your Gemfile:

```ruby
gem 'arj', '~> 0.0'
```

Or install the Gem:

```bash
gem install arj
```

Apply the following DB migration:

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

If using Rails, configure the queue adapter:

```ruby
class MyApplication < Rails::Application
  config.active_job.queue_adapter = :arj
end
```

If not using Rails, configure the queue adapter:

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
```

```ruby
SampleJob.all # All SampleJobs
```

## Persistence

The `Arj` module exposes ActiveRecord-like persistence methods. For example:

```ruby
Arj.exists?(job)
Arj.reload(job)
Arj.save!(job)
Arj.update!(job, attributes)
Arj.destroy!(job)
Arj.destroy?(job)
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

## Worker

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

Apply a migration:

```ruby
class AddShardToJobs < ActiveRecord::Migration[7.1]
  def change
    add_column :jobs, :shard, :string
  end
end
```

Include the shard extension:

```ruby
class SampleJob < ActiveJob::Base
  include Arj::Extensions::Shard
end
```

Usage:

```ruby
SampleJob.set(shard: 'some shard').perform_later('foo')
```

### Last error

Apply a migration:

```ruby
class AddLastErrorToJobs < ActiveRecord::Migration[7.1]
  def change
    add_column :jobs, :last_error, :text
  end
end
```

Include the last error extension:

```ruby
class SampleJob < ActiveJob::Base
  include Arj::Extensions::LastError
end
```

## Testing

The following sample jobs are provided for use in tests:

- `Arj::Test::Job`
- `Arj::Test::JobWithShard`
- `Arj::Test::JobWithLastError`

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
