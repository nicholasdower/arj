# frozen_string_literal: true

require 'active_record'
require_relative 'persistence'
require_relative '../arj'
require_relative '../arj/documentation/active_record_relation'

module Arj
  # A wrapper for {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation ActiveRecord::Relation} which
  # returns jobs rather than records. Also provides additional, Arj-specific query methods like {#todo todo},
  # {#failing failing}, {#queue queue}.
  #
  # Note that records will not be mapped to jobs if they are missing one or more attributes (for instance when using
  # {#select select}).
  #
  # See: {Arj::Extensions::Query}
  class Relation
    # List of Arj-specific query methods.
    #
    # @return [Array<Symbol>]
    QUERY_METHODS = %i[failing queue executable todo discarded].freeze

    include Arj::Documentation::ActiveRecordRelation
    include Arj::Documentation::Enumerable

    # Returns an Arj::Relation which wraps the specified ActiveRecord Relation, WhereChain, etc.
    def initialize(ar_relation)
      @ar_relation = ar_relation
    end

    # Delegates to the wrapped ActiveRecord relation and maps record objects to job objects.
    #
    # @param method [Symbol]
    def method_missing(method, *args, &block)
      result = if block
                 @ar_relation.send(method, *args) do |*inner_args, &inner_block|
                   inner_args = inner_args.map { |arg| map_result(arg) }
                   block.call(*inner_args, &inner_block)
                 end
               else
                 @ar_relation.send(method, *args)
               end
      map_result(result)
    end

    # Implemented to ensure Arj::Relation#method can be used to retrieve methods provided by ActiveRecord relations.
    #
    # @return [Boolean]
    def respond_to_missing?(*several_variants)
      @ar_relation.respond_to?(*several_variants)
    end

    # Returns a {Relation} scope for jobs which have been executed one or more times.
    #
    # @return [Arj::Relation]
    def failing
      where('executions > ?', 0)
    end

    # Returns a {Relation} scope for jobs where +discarded_at+ is not +null+.
    #
    # See: [Arj::Extensions::RetainDiscarded]
    #
    # @return [Arj::Relation]
    def discarded
      unless Arj.record_class.attribute_names.include?('discarded_at')
        raise "#{Arj.record_class.name} class missing discarded_at attribute"
      end

      where('discarded_at is not null')
    end

    # Returns a {Relation} scope for jobs in the specified queue(s).
    #
    # @param queues [Array<String]
    # @return [Arj::Relation]
    def queue(*queues)
      where(queue_name: queues)
    end

    # Returns a {Relation} scope for jobs with a +scheduled_at+ that is either +null+ or in the past.
    #
    # @return [Arj::Relation]
    def executable
      relation = where('scheduled_at is null or scheduled_at <= ?', Time.now.utc)
      relation = relation.where('discarded_at is null') if Arj.record_class.attribute_names.include?('discarded_at')

      relation
    end

    # Returns a {Relation} scope for {executable} jobs in order.
    #
    # Jobs are ordered by:
    # - +priority+ (+null+ last)
    # - +scheduled_at+ (+null+ last)
    # - +enqueued_at+
    #
    # @return [Arj::Relation]
    def todo
      executable.order(
        Arel.sql(
          <<~SQL.squish
            CASE WHEN priority IS NULL THEN 1 ELSE 0 END, priority,
            CASE WHEN scheduled_at IS NULL THEN 1 ELSE 0 END, scheduled_at,
            enqueued_at
          SQL
        )
      )
    end

    # Updates each matching job with the specified attributes.
    #
    # @param attributes [Hash]
    # @return [Array<ActiveJob::Base>]
    def update_job!(attributes)
      to_a.map do |job|
        raise "unexpected job: #{job.class}" unless job.is_a?(ActiveJob::Base)

        job.update!(attributes)
        job
      end
    end

    # Implemented to provide +pretty_inspect+ output containing arrays of jobs rather than arrays of records, similar to
    # the output produced when calling +pretty_inspect+ on ActiveRecord::Relation.
    #
    # Instead of the default +pretty_inspect+ output:
    #    :002 > Arj.all
    #    =>
    #   #<Arj::Relation:0x000000010a05a6f8
    #    @ar_relation=
    #     [#<Arj::Test::Job:0x0000000105f74c60
    #
    # Produces:
    #    :002 > Arj.all
    #    =>
    #   [#<Arj::Test::Job:0x0000000105f74c60
    #
    # @param pp [PP]
    # @return [NilClass]
    def pretty_print(pp)
      pp.pp(to_a)
    end

    private

    def map_result(result)
      case result
      when ActiveRecord::Relation
        Relation.new(result)
      when Enumerator
        Enumerator.new do |yielder|
          result.each do |yielded|
            yielder << map_result(yielded)
          end
        end
      when Array
        result.map do |item|
          if item.is_a?(Arj.record_class)
            maybe_to_job(item)
          else
            item
          end
        end
      when Arj.record_class
        maybe_to_job(result)
      else
        result
      end
    end

    def maybe_to_job(record)
      # If all attributes are present, return a job, otherwise, return the record.
      # Attributes may be missing if, for instance, `select` was used.
      if (Arj.record_class.attribute_names - record.attributes.keys).empty?
        Persistence.from_record(record)
      else
        record
      end
    end
  end
end
