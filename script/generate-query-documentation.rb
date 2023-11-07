#!/usr/bin/env ruby

# frozen_string_literal: true

require 'active_record'
require 'active_record/relation'
require 'stringio'

class QueryDocumentationGenerator
  OUTPUT_FILE = 'lib/arj/query_documentation.rb'
  METHODS = ActiveRecord::Querying::QUERYING_METHODS
  CLASSES = [ActiveRecord::Relation].freeze
  DEFAULT_BASE_PATH = 'https://www.rubydoc.info/github/rails/rails'

  def initialize(base_path = DEFAULT_BASE_PATH)
    @base_path = base_path
  end

  def generate_all
    warn "info: generating #{OUTPUT_FILE}"
    found = []
    out = StringIO.new
    out.puts <<~DOC
      # frozen_string_literal: true

      module Arj
        # Provides documentation (and autocomplete) for ActiveRecord query methods.
        #
        # See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation ActiveRecord::Relation}
        module QueryDocumentation
    DOC

    CLASSES.each do |clazz|
      found = found.concat(generate(clazz, out))
    end

    out.puts <<~DOC
        end
      end
    DOC
    undocumented = METHODS - found
    warn "error: undocumented methods: #{undocumented}" if undocumented.any?

    duplicated = found.select{ |method| found.count(method) > 1 }
    warn "error: duplicate methods: #{duplicated}" if duplicated.any?

    raise "error: undocumented methods: #{undocumented}" if undocumented.any?
    raise "error: duplicate methods: #{duplicated}" if duplicated.any?

    File.write(OUTPUT_FILE, out.string)
  end

  private

  def generate(clazz, out = STDOUT)
    clazz_methods = clazz.public_instance_methods
    path = clazz.name.gsub('::', '/')
    intersection = METHODS.intersection(clazz_methods)
    intersection.each do |method|
      out.puts <<~DOC.gsub(/^\|/, '')
        |    # @!method #{method}
        |    #   See: {#{@base_path}/#{path}\##{method}-instance_method #{clazz.name}\##{method}}
      DOC
    end
    intersection
  end
end

QueryDocumentationGenerator.new.generate_all
