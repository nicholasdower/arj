# frozen_string_literal: true

require_relative '../arj'
require_relative 'relation'

module Arj
  module QueryMethods
    module ClassMethods
      delegate(*ActiveRecord::Querying::QUERYING_METHODS, to: :all)

      def all
        raise 'no record class configured' unless Arj.record_class

        if self == Arj || name == 'ApplicationJob'
          Relation.new(Arj.record_class.all)
        else
          Relation.new(Arj.record_class.where(job_class: name).all)
        end
      end
    end

    def self.included(clazz)
      clazz.extend ClassMethods
    end
  end
end
