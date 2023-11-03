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
    attr_writer :record_class, :base_classes

    def record_class
      @record_class ||= 'Job'.constantize
    end

    def base_classes
      @base_classes ||= %w[ApplicationJob]
    end

    def next(queue_name: nil, max_executions: nil)
      relation = Arj.where('scheduled_at is null or scheduled_at < ?', Time.zone.now)
      relation = relation.where(queue_name:) if queue_name
      relation = relation.where('executions < ?', max_executions) if max_executions
      relation.order(priority: :asc, scheduled_at: :asc).first
    end
  end
end
