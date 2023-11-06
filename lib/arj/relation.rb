# frozen_string_literal: true

require 'active_record'
require_relative 'persistence'
require_relative '../arj'

module Arj
  # Wrapper for +ActiveRecord::Relation+ which maps record objects to job objects.
  #
  # See {Query}
  class Relation
    # Returns an Arj::Relation which wraps the specified ActiveRecord Relation, WhereChain, etc.
    def initialize(ar_relation)
      @ar_relation = ar_relation
    end

    # Delegates to the wrapped ActiveRecord relation and maps record objects to job objects.
    def method_missing(method, *, &)
      result = @ar_relation.send(method, *, &)
      case result
      when ActiveRecord::Relation, ActiveRecord::QueryMethods::WhereChain
        Relation.new(result)
      when Array
        result.map do |item|
          if item.is_a?(Arj.record_class)
            Persistence.from_record(item)
          else
            item
          end
        end
      when Arj.record_class
        Persistence.from_record(result)
      else
        result
      end
    end

    # Implemented to ensure Arj::Relation#method can be used to retrieve methods provided by ActiveRecord relations.
    #
    # @return [Boolean]
    def respond_to_missing?(*)
      @ar_relation.respond_to?(*)
    end

    # Updates each matching job with the specified attributes.
    #
    # @return [Array<ActiveJob::Base>]
    def update_job!(attributes)
      to_a.map do |job|
        job.update!(attributes)
        job
      end
    end

    # Implemented to provide +pretty_inspect+ output containing arrays of jobs rather than arrays of records, similar to
    # the output produced when calling +pretty_inspect+ on ActiveRecord::Relation.
    #
    # Instead of the default +pretty_inspect+ output:
    #   [1] pry(main)> Arj.all
    #   => #<Arj::Relation:0x000000010bc44508
    #   @ar_relation=
    #    [#<Job:0x000000010b54b2d8
    #     id: 1,
    #     ...
    #
    # Produces:
    #   [1] pry(main)> Arj.all
    #   => [#<Arj::Test::Job:0x0000000110ab0840
    #     @_scheduled_at_time=nil,
    #     @arguments=[],
    #     ...
    #
    # @return [NilClass]
    def pretty_print(pp)
      pp.pp(to_a)
    end
  end
end
