# Arj

An ActiveJob queuing backend which uses ActiveRecord. 

For more information on ActiveJob, see:

- https://edgeguides.rubyonrails.org/active_job_basics.html
- https://www.rubydoc.info/gems/activejob

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
Arj.all                            # All jobs
Arj.where(queue_name: 'foo')       # Jobs in the foo queue
```

Optionally, query methods can also be added to job classes:

```ruby
class SampleJob < ActiveJob::Base
  include Arj::QueryMethods
end
```

```ruby
SampleJob.all                   # All SampleJobs
```

## Persistence

Optionally, persistence methods `reload`, `save!`, `destroy!`, `update!` and `update_job!` can be added to job classes:

```ruby
class SampleJob < ActiveJob::Base
  include Arj::Persistence
end
```

## Worker

Run all availble jobs using a worker:

```ruby
Arj::Worker.new.work_off
```

Start a worker which will run jobs as they become available:

```ruby
Arj::Worker.new.start
```

## Customization Examples

### Adding a shard column

Apply a migration:

```ruby
class AddShardToJobs < ActiveRecord::Migration[7.1]
  def change
    add_column :jobs, :shard, :string
  end
end
```

Override `#set`, `#serialize` and `#deserialize`:

```ruby
class SampleJob < ActiveJob::Base
  attr_accessor :shard

  def set(options = {})
    super.tap { @shard = options[:shard] if options.key?(:shard) }
  end

  def serialize
    super.merge('shard' => @shard)
  end

  def deserialize(record)
    super.tap { @shard = record.shard }
  end
end
```

Usage:

```ruby
SampleJob.set(shard: 22).perform_later('foo')
```

### Adding a last error column

Apply a migration:

```ruby
class AddLastErrorToJobs < ActiveRecord::Migration[7.1]
  def change
    add_column :jobs, :last_error, :text
  end
end
```

Configure retries and override `#serialize` and `#deserialize`:

```ruby
class SampleJob < ActiveJob::Base
  attr_accessor :last_error

  retry_on Exception

  def set(options = nil)
    super
    if (error = options[:error])
      backtrace = error.backtrace&.map { |line| "\t#{line}" }&.join("\n")
      error = backtrace ? "#{error.class}: #{error.message}\n#{backtrace}" : "#{error.class}: #{error.message}"

      @last_error = error&.truncate(65535, omission: '… (truncated)')
    end
  end

  def serialize
    super.merge('last_error' => @last_error)
  end

  def deserialize_record(record)
    super.tap { @last_error = record.last_error }
  end
end
```

## Testing

The following sample jobs are provided for use in tests:

- `TestJob`
- `TestJobWithPersistence`
- `TestJobWithQuery`
- `TestJobWithRetry`

To test job failures:

```ruby
Arj::TestJobWithRetry.perform_later(error: StandardError)
```

To test retries:
```ruby
Arj::TestJobWithRetry.perform_later(error: Arj::TestJobWithRetry::Error)
```
