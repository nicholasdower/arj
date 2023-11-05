# frozen_string_literal: true

require 'active_record'
require_relative 'persistence'
require_relative '../arj'

module Arj
  # Wrapper for +ActiveRecord::Relation+ which maps record objects to job objects.
  #
  # See {Query}
  class Relation
    def initialize(ar_relation)
      @ar_relation = ar_relation
    end

    def method_missing(method, *, &)
      result = @ar_relation.send(method, *, &)
      case result
      when ActiveRecord::Relation, ActiveRecord::QueryMethods::WhereChain
        Relation.new(result)
      when Array
        result.map do |item|
          if item.is_a?(Arj.record_class)
            job = Persistence.from_record(item)
            Persistence.enhance(job)
          else
            item
          end
        end
      when Arj.record_class
        job = Persistence.from_record(result)
        Persistence.enhance(job)
      else
        result
      end
    end

    def respond_to_missing?(*)
      @ar_relation.respond_to?(*)
    end

    # Updates each matching job with the specified attributes.
    def update_job!(attributes)
      to_a.map do |job|
        job.update!(attributes)
      end
    end

    def pretty_print(pp)
      pp.pp(to_a)
    end
  end
end
