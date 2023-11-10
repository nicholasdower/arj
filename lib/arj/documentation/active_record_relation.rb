# frozen_string_literal: true

module Arj
  module Documentation
    # Provides documentation (and autocomplete) for
    # {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation ActiveRecord::Relation}
    # query methods.
    module ActiveRecordRelation
      # @!method and
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#and-instance_method ActiveRecord::Relation#and}
      # @!method annotate
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#annotate-instance_method ActiveRecord::Relation#annotate}
      # @!method any?
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#any?-instance_method ActiveRecord::Relation#any?}
      # @!method async_average
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#async_average-instance_method ActiveRecord::Relation#async_average}
      # @!method async_count
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#async_count-instance_method ActiveRecord::Relation#async_count}
      # @!method async_ids
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#async_ids-instance_method ActiveRecord::Relation#async_ids}
      # @!method async_maximum
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#async_maximum-instance_method ActiveRecord::Relation#async_maximum}
      # @!method async_minimum
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#async_minimum-instance_method ActiveRecord::Relation#async_minimum}
      # @!method async_pick
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#async_pick-instance_method ActiveRecord::Relation#async_pick}
      # @!method async_pluck
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#async_pluck-instance_method ActiveRecord::Relation#async_pluck}
      # @!method async_sum
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#async_sum-instance_method ActiveRecord::Relation#async_sum}
      # @!method average
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#average-instance_method ActiveRecord::Relation#average}
      # @!method calculate
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#calculate-instance_method ActiveRecord::Relation#calculate}
      # @!method count
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#count-instance_method ActiveRecord::Relation#count}
      # @!method create_or_find_by
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#create_or_find_by-instance_method ActiveRecord::Relation#create_or_find_by}
      # @!method create_or_find_by!
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#create_or_find_by!-instance_method ActiveRecord::Relation#create_or_find_by!}
      # @!method create_with
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#create_with-instance_method ActiveRecord::Relation#create_with}
      # @!method delete_all
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#delete_all-instance_method ActiveRecord::Relation#delete_all}
      # @!method delete_by
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#delete_by-instance_method ActiveRecord::Relation#delete_by}
      # @!method destroy_all
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#destroy_all-instance_method ActiveRecord::Relation#destroy_all}
      # @!method destroy_by
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#destroy_by-instance_method ActiveRecord::Relation#destroy_by}
      # @!method distinct
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#distinct-instance_method ActiveRecord::Relation#distinct}
      # @!method eager_load
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#eager_load-instance_method ActiveRecord::Relation#eager_load}
      # @!method except
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#except-instance_method ActiveRecord::Relation#except}
      # @!method excluding
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#excluding-instance_method ActiveRecord::Relation#excluding}
      # @!method exists?
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#exists?-instance_method ActiveRecord::Relation#exists?}
      # @!method extending
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#extending-instance_method ActiveRecord::Relation#extending}
      # @!method extract_associated
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#extract_associated-instance_method ActiveRecord::Relation#extract_associated}
      # @!method fifth
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#fifth-instance_method ActiveRecord::Relation#fifth}
      # @!method fifth!
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#fifth!-instance_method ActiveRecord::Relation#fifth!}
      # @!method find
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#find-instance_method ActiveRecord::Relation#find}
      # @!method find_by
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#find_by-instance_method ActiveRecord::Relation#find_by}
      # @!method find_by!
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#find_by!-instance_method ActiveRecord::Relation#find_by!}
      # @!method find_each
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#find_each-instance_method ActiveRecord::Relation#find_each}
      # @!method find_in_batches
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#find_in_batches-instance_method ActiveRecord::Relation#find_in_batches}
      # @!method find_or_create_by
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#find_or_create_by-instance_method ActiveRecord::Relation#find_or_create_by}
      # @!method find_or_create_by!
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#find_or_create_by!-instance_method ActiveRecord::Relation#find_or_create_by!}
      # @!method find_or_initialize_by
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#find_or_initialize_by-instance_method ActiveRecord::Relation#find_or_initialize_by}
      # @!method find_sole_by
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#find_sole_by-instance_method ActiveRecord::Relation#find_sole_by}
      # @!method first
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#first-instance_method ActiveRecord::Relation#first}
      # @!method first!
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#first!-instance_method ActiveRecord::Relation#first!}
      # @!method first_or_create
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#first_or_create-instance_method ActiveRecord::Relation#first_or_create}
      # @!method first_or_create!
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#first_or_create!-instance_method ActiveRecord::Relation#first_or_create!}
      # @!method first_or_initialize
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#first_or_initialize-instance_method ActiveRecord::Relation#first_or_initialize}
      # @!method forty_two
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#forty_two-instance_method ActiveRecord::Relation#forty_two}
      # @!method forty_two!
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#forty_two!-instance_method ActiveRecord::Relation#forty_two!}
      # @!method fourth
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#fourth-instance_method ActiveRecord::Relation#fourth}
      # @!method fourth!
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#fourth!-instance_method ActiveRecord::Relation#fourth!}
      # @!method from
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#from-instance_method ActiveRecord::Relation#from}
      # @!method group
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#group-instance_method ActiveRecord::Relation#group}
      # @!method having
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#having-instance_method ActiveRecord::Relation#having}
      # @!method ids
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#ids-instance_method ActiveRecord::Relation#ids}
      # @!method in_batches
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#in_batches-instance_method ActiveRecord::Relation#in_batches}
      # @!method in_order_of
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#in_order_of-instance_method ActiveRecord::Relation#in_order_of}
      # @!method includes
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#includes-instance_method ActiveRecord::Relation#includes}
      # @!method invert_where
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#invert_where-instance_method ActiveRecord::Relation#invert_where}
      # @!method joins
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#joins-instance_method ActiveRecord::Relation#joins}
      # @!method last
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#last-instance_method ActiveRecord::Relation#last}
      # @!method last!
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#last!-instance_method ActiveRecord::Relation#last!}
      # @!method left_joins
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#left_joins-instance_method ActiveRecord::Relation#left_joins}
      # @!method left_outer_joins
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#left_outer_joins-instance_method ActiveRecord::Relation#left_outer_joins}
      # @!method limit
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#limit-instance_method ActiveRecord::Relation#limit}
      # @!method lock
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#lock-instance_method ActiveRecord::Relation#lock}
      # @!method many?
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#many?-instance_method ActiveRecord::Relation#many?}
      # @!method maximum
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#maximum-instance_method ActiveRecord::Relation#maximum}
      # @!method merge
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#merge-instance_method ActiveRecord::Relation#merge}
      # @!method minimum
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#minimum-instance_method ActiveRecord::Relation#minimum}
      # @!method none
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#none-instance_method ActiveRecord::Relation#none}
      # @!method none?
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#none?-instance_method ActiveRecord::Relation#none?}
      # @!method offset
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#offset-instance_method ActiveRecord::Relation#offset}
      # @!method one?
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#one?-instance_method ActiveRecord::Relation#one?}
      # @!method only
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#only-instance_method ActiveRecord::Relation#only}
      # @!method optimizer_hints
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#optimizer_hints-instance_method ActiveRecord::Relation#optimizer_hints}
      # @!method or
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#or-instance_method ActiveRecord::Relation#or}
      # @!method order
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#order-instance_method ActiveRecord::Relation#order}
      # @!method pick
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#pick-instance_method ActiveRecord::Relation#pick}
      # @!method pluck
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#pluck-instance_method ActiveRecord::Relation#pluck}
      # @!method preload
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#preload-instance_method ActiveRecord::Relation#preload}
      # @!method readonly
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#readonly-instance_method ActiveRecord::Relation#readonly}
      # @!method references
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#references-instance_method ActiveRecord::Relation#references}
      # @!method regroup
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#regroup-instance_method ActiveRecord::Relation#regroup}
      # @!method reorder
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#reorder-instance_method ActiveRecord::Relation#reorder}
      # @!method reselect
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#reselect-instance_method ActiveRecord::Relation#reselect}
      # @!method rewhere
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#rewhere-instance_method ActiveRecord::Relation#rewhere}
      # @!method second
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#second-instance_method ActiveRecord::Relation#second}
      # @!method second!
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#second!-instance_method ActiveRecord::Relation#second!}
      # @!method second_to_last
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#second_to_last-instance_method ActiveRecord::Relation#second_to_last}
      # @!method second_to_last!
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#second_to_last!-instance_method ActiveRecord::Relation#second_to_last!}
      # @!method select
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#select-instance_method ActiveRecord::Relation#select}
      # @!method sole
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#sole-instance_method ActiveRecord::Relation#sole}
      # @!method strict_loading
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#strict_loading-instance_method ActiveRecord::Relation#strict_loading}
      # @!method sum
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#sum-instance_method ActiveRecord::Relation#sum}
      # @!method take
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#take-instance_method ActiveRecord::Relation#take}
      # @!method take!
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#take!-instance_method ActiveRecord::Relation#take!}
      # @!method third
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#third-instance_method ActiveRecord::Relation#third}
      # @!method third!
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#third!-instance_method ActiveRecord::Relation#third!}
      # @!method third_to_last
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#third_to_last-instance_method ActiveRecord::Relation#third_to_last}
      # @!method third_to_last!
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#third_to_last!-instance_method ActiveRecord::Relation#third_to_last!}
      # @!method touch_all
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#touch_all-instance_method ActiveRecord::Relation#touch_all}
      # @!method unscope
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#unscope-instance_method ActiveRecord::Relation#unscope}
      # @!method update_all
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#update_all-instance_method ActiveRecord::Relation#update_all}
      # @!method where
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#where-instance_method ActiveRecord::Relation#where}
      # @!method with
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#with-instance_method ActiveRecord::Relation#with}
      # @!method without
      #   See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#without-instance_method ActiveRecord::Relation#without}
    end
  end
end
