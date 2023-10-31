# frozen_string_literal: true

require 'active_record'

module Arj
  # Wrapper for ActiveRecord relations which maps record objects to Arj::Job objects.
  class Relation
    def initialize(active_record_relation)
      @active_record_relation = active_record_relation
    end

    def method_missing(symbol, *)
      result = @active_record_relation.send(symbol, *)
      case result
      when ActiveRecord::Relation, ActiveRecord::QueryMethods::WhereChain
        Relation.new(result)
      when Array
        result.map do |item|
          if item.is_a?(Arj::Base.record_class)
            item.job_class.constantize.from_record(item)
          else
            item
          end
        end
      when Arj::Base.record_class
        result.job_class.constantize.from_record(result)
      else
        result
      end
    end

    def respond_to_missing?(name, include_private)
      respond_to?(name, include_private)
    end
  end
end
