# frozen_string_literal: true

require_relative 'arj_adapter.rb'
require_relative 'arj/job.rb'
require_relative 'arj/relation.rb'
require_relative 'arj/worker.rb'
require_relative 'version.rb'

# Arj helper methods
module Arj
  def self.model_class_name=(name)
    raise "string expected: #{name}" unless name.is_a?(String)

    @model_class_name = name
  end

  def self.model_class
    @model_class ||= @model_class_name&.constantize
    @model_class
  end

  class << self
    delegate :where, :count, :first, :last, :sole, :take, :pluck, :destroy_all, :destroy, to: :all
  end

  def self.all
    Relation.new(model_class.all)
  end

  def self.from(record)
    raise "expected #{Arj.model_class}, found #{record.class}" unless record.is_a?(Arj.model_class)

    job = Object.const_get(record.job_class).new
    raise "expected ArjJob, found #{job.class}" unless job.is_a?(Arj::Job)

    job.arj_deserialize(record)
  end

  def self.next(queue_name: nil, max_executions: nil)
    relation = where('scheduled_at is null or scheduled_at < ?', Time.zone.now)
    relation = relation.where(queue_name:) if queue_name
    relation = relation.where('executions < ?', max_executions) if max_executions
    relation.order(priority: :asc, scheduled_at: :asc).first
  end
end
