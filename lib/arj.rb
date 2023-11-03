# frozen_string_literal: true

require 'active_record'
require_relative 'arj_adapter'
require_relative 'arj/persistence'
require_relative 'arj/query_methods'
require_relative 'arj/relation'
require_relative 'arj/version'
require_relative 'arj/worker'

module Arj
  class << self
    include QueryMethods::ClassMethods

    def record_class=(clazz)
      raise "invalid record class: #{clazz}" unless clazz < ActiveRecord::Base || clazz.is_a?(String)

      @record_class = clazz
    end

    def record_class
      unless @record_class
        record_class = 'Job'.constantize
        raise "invalid record class: #{record_class}" unless record_class < ActiveRecord::Base

        @record_class = record_class
      end

      @record_class
    end
  end
end
