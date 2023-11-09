# frozen_string_literal: true

require_relative '../../arj'

module Arj
  module Documentation
    module Generator
      def self.generate_all
        Generator.generate(
          'lib/arj/documentation/active_record_relation.rb',
          Arj::Documentation::ActiveRecordRelation.name,
          ActiveRecord::Relation,
          ActiveRecord::Querying::QUERYING_METHODS,
          'See: {https://www.rubydoc.info/github/rails/rails/ActiveRecord/Relation#%<method>s-instance_method ' \
          '%<class>s#%<method>s}'
        )
        Generator.generate(
          'lib/arj/documentation/arj_relation.rb',
          Arj::Documentation::ArjRelation.name,
          Arj::Relation,
          Arj::Relation::QUERY_METHODS,
          'See: {%<class>s#%<method>s}'
        )
        Generator.generate(
          'lib/arj/documentation/enumerable.rb',
          Arj::Documentation::Enumerable.name,
          ::Enumerable,
          ::Enumerable.public_instance_methods - ActiveRecord::Querying::QUERYING_METHODS,
          'See: {https://rubydoc.info/stdlib/core/Enumerable#%<method>s-instance_method %<class>s#%<method>s}'
        )
      end

      def self.generate(file_path, module_name, source, methods, see_format)
        out = StringIO.new

        lines = File.readlines(file_path).map(&:chomp)
        raise 'head not found' unless (index = lines.index { |l| l.match(/ *module #{module_name.split('::').last}/) })

        indentation = lines[index].match(/^( *)module/)[1]
        head = lines[0..index].join("\n")
        out.puts(head)

        found = methods.intersection(source.public_instance_methods)
        found.each do |method|
          out.puts("#{indentation}  # @!method #{method}")
          out.puts("#{indentation}  #   #{format(see_format, class: source, method: method)}")
        end

        not_found = methods - found
        raise "undocumented methods: #{not_found}" if not_found.any?

        raise 'tail not found' unless (index = lines.index("#{indentation}end"))

        tail = lines[index..].join("\n")
        out.puts(tail)

        File.write(file_path, out.string)
      end
    end
  end
end
