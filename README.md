# Arj (Active Record Job)

An ActiveJob queuing backend which uses ActiveRecord. 

For more information on ActiveJob, see:

- https://edgeguides.rubyonrails.org/active_job_basics.html
- https://www.rubydoc.info/gems/activejob

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

Optionally, create a class named `ApplicationJob` which extends from `Arj::Base`:

```ruby
require 'arj'

class ApplicationJob < Arj::Base; end
```

## Usage

Create a job class with a perform method. Specify the arguments required for your job:

```ruby
require 'arj'

class SampleJob < ApplicationJob
  def perform(arg: nil, error: nil)
    ActiveJob::Base.logger.info "SampleJob#perform #{job_id} - arg: #{arg}, error: #{error}"
    raise StandardError.new(error) if error

    arguments
  end
end
```

Enqueue and run a job which will succeed:

```ruby
job_one = SampleJob.perform_later(arg: 'foo')
job_one.perform_now
```

Enqueue a job in the future:

```ruby
job_one = SampleJob.set(wait: 10.seconds).perform_later(arg: 'foo')
```

Enqueue and run a job which will fail:

```ruby
job_two = SampleJob.perform_later(error: 'failed')
job_two.perform_now
```

Retrieve jobs (many `ActiveRecord` query methods are supported):

```ruby
SampleJob.all                      # SampleJobs
ApplicationJob.all                 # Jobs of all types
Arj::Base.all                      # Jobs of all types
Arj::Base.where(queue_name: 'foo') # Jobs in a particular queue
```

Run all availble jobs using a worker:

```ruby
Arj::Worker.new.work_off
```

Start a worker which will run jobs as they become available:

```ruby
Arj::Worker.new.start
```

## Extension Examples

### Custom retry scheduling

Override `ApplicationJob#retry_job`:

```ruby
class ApplicationJob < Arj::Base
  def retry_job(options = {})
    options[:wait] = 5 + (executions**4) unless options[:wait] || options[:wait_until]
    super
  end
end
```

### Adding a shard column

Apply a migration:

```ruby
class AddShardToJobs < ActiveRecord::Migration[7.1]
  def change
    add_column :jobs, :shard, :string
  end
end
```

Override `#set`, `#serialize` and `#deserialize_record`:

```ruby
class ApplicationJob < Arj::Base
  attr_accessor :shard

  def set(options = {})
    super.tap { @shard = options[:shard] if options.key?(:shard) }
  end

  def serialize
    super.merge('shard' => @shard)
  end

  def deserialize_record(record)
    super.tap { @shard = record.shard }
  end
end
```

Enqueue a job with a shard:

```ruby
SampleJob.set(shard: 22).perform_later(arg: 'foo')
```

### Adding a last error column

Apply a migration:

```ruby
class AddShardToJobs < ActiveRecord::Migration[7.1]
  def change
    add_column :jobs, :last_error, :text
  end
end
```

Override `#rescue_from`, `#serialize` and `#deserialize_record`:

```ruby
class ApplicationJob < Arj::Base
  attr_accessor :last_error

  rescue_from(Exception) do |error|
    self.last_error = error
    retry_job
  end

  def last_error=(error)
    raise "unexpected error #{error.class}" unless error.nil? || error.is_a?(Exception) || error.is_a?(String)

    if error.is_a?(Exception)
      backtrace = error.backtrace&.map { |line| "\t#{line}" }&.join("\n")
      error = backtrace ? "#{error.class}: #{error.message}\n#{backtrace}" : "#{error.class}: #{error.message}"
    end

    @last_error = error&.truncate(65535, omission: '… (truncated)')

    self
  end

  def serialize
    super.merge('last_error' => @last_error)
  end

  def deserialize_record(record)
    super.tap { @last_error = record.last_error }
  end
end
```

Enqueue and run a job which will fail:

```ruby
job = SampleJob.perform_later(error: 'failed')
job.perform_now
puts job.last_error
```

