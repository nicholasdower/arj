# frozen_string_literal: true

module Arj
  module Documentation
    # Provides documentation (and autocomplete) for Enumerable methods.
    module Enumerable
      # @!method all?
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#all?-instance_method Enumerable#all?}
      # @!method as_json
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#as_json-instance_method Enumerable#as_json}
      # @!method chain
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#chain-instance_method Enumerable#chain}
      # @!method chunk
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#chunk-instance_method Enumerable#chunk}
      # @!method chunk_while
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#chunk_while-instance_method Enumerable#chunk_while}
      # @!method collect
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#collect-instance_method Enumerable#collect}
      # @!method collect_concat
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#collect_concat-instance_method Enumerable#collect_concat}
      # @!method compact
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#compact-instance_method Enumerable#compact}
      # @!method compact_blank
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#compact_blank-instance_method Enumerable#compact_blank}
      # @!method cycle
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#cycle-instance_method Enumerable#cycle}
      # @!method detect
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#detect-instance_method Enumerable#detect}
      # @!method drop
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#drop-instance_method Enumerable#drop}
      # @!method drop_while
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#drop_while-instance_method Enumerable#drop_while}
      # @!method each_cons
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#each_cons-instance_method Enumerable#each_cons}
      # @!method each_entry
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#each_entry-instance_method Enumerable#each_entry}
      # @!method each_slice
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#each_slice-instance_method Enumerable#each_slice}
      # @!method each_with_index
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#each_with_index-instance_method Enumerable#each_with_index}
      # @!method each_with_object
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#each_with_object-instance_method Enumerable#each_with_object}
      # @!method entries
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#entries-instance_method Enumerable#entries}
      # @!method exclude?
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#exclude?-instance_method Enumerable#exclude?}
      # @!method filter
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#filter-instance_method Enumerable#filter}
      # @!method filter_map
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#filter_map-instance_method Enumerable#filter_map}
      # @!method find_all
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#find_all-instance_method Enumerable#find_all}
      # @!method find_index
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#find_index-instance_method Enumerable#find_index}
      # @!method flat_map
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#flat_map-instance_method Enumerable#flat_map}
      # @!method grep
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#grep-instance_method Enumerable#grep}
      # @!method grep_v
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#grep_v-instance_method Enumerable#grep_v}
      # @!method group_by
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#group_by-instance_method Enumerable#group_by}
      # @!method include?
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#include?-instance_method Enumerable#include?}
      # @!method including
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#including-instance_method Enumerable#including}
      # @!method index_by
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#index_by-instance_method Enumerable#index_by}
      # @!method index_with
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#index_with-instance_method Enumerable#index_with}
      # @!method inject
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#inject-instance_method Enumerable#inject}
      # @!method lazy
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#lazy-instance_method Enumerable#lazy}
      # @!method map
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#map-instance_method Enumerable#map}
      # @!method max
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#max-instance_method Enumerable#max}
      # @!method max_by
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#max_by-instance_method Enumerable#max_by}
      # @!method member?
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#member?-instance_method Enumerable#member?}
      # @!method min
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#min-instance_method Enumerable#min}
      # @!method min_by
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#min_by-instance_method Enumerable#min_by}
      # @!method minmax
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#minmax-instance_method Enumerable#minmax}
      # @!method minmax_by
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#minmax_by-instance_method Enumerable#minmax_by}
      # @!method partition
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#partition-instance_method Enumerable#partition}
      # @!method reduce
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#reduce-instance_method Enumerable#reduce}
      # @!method reject
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#reject-instance_method Enumerable#reject}
      # @!method reverse_each
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#reverse_each-instance_method Enumerable#reverse_each}
      # @!method slice_after
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#slice_after-instance_method Enumerable#slice_after}
      # @!method slice_before
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#slice_before-instance_method Enumerable#slice_before}
      # @!method slice_when
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#slice_when-instance_method Enumerable#slice_when}
      # @!method sort
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#sort-instance_method Enumerable#sort}
      # @!method sort_by
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#sort_by-instance_method Enumerable#sort_by}
      # @!method take_while
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#take_while-instance_method Enumerable#take_while}
      # @!method tally
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#tally-instance_method Enumerable#tally}
      # @!method to_a
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#to_a-instance_method Enumerable#to_a}
      # @!method to_h
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#to_h-instance_method Enumerable#to_h}
      # @!method to_json
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#to_json-instance_method Enumerable#to_json}
      # @!method to_set
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#to_set-instance_method Enumerable#to_set}
      # @!method uniq
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#uniq-instance_method Enumerable#uniq}
      # @!method zip
      #   See: {https://rubydoc.info/stdlib/core/Enumerable#zip-instance_method Enumerable#zip}
    end
  end
end
