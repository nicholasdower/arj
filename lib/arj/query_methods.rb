# frozen_string_literal: true

require_relative '../arj'
require_relative 'relation'

module Arj
  module QueryMethods
    module ClassMethods
      delegate :all, :where, :count, :first, :last, :sole, :take, :pluck, :destroy_all, :destroy, to: :record_relation

      def record_relation
        raise 'no record class configured' unless Arj.record_class

        if self == Arj || name == 'ApplicationJob'
          Relation.new(Arj.record_class)
        else
          Relation.new(Arj.record_class.where(job_class: name))
        end
      end
    end

    def self.included(clazz)
      clazz.extend ClassMethods
    end
  end
end
