# frozen_string_literal: true

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
          if item.is_a?(Arj.model_class)
            Arj.from(item)
          else
            item
          end
        end
      when Arj.model_class
        Arj.from(result)
      else
        result
      end
    end

    def respond_to_missing?(name, include_private)
      respond_to?(name, include_private)
    end

    def pretty_print(pp)
      pp.pp(to_a)
    end
  end
end
