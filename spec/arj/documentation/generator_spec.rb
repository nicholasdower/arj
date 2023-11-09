# frozen_string_literal: true

require_relative '../../spec_helper'

describe Arj::Documentation::Generator do
  context '.generate' do
    subject do
      described_class.generate(file.path, module_name, source, methods, format_string)
    end

    let(:original_file_content) do
      <<~RUBY
        require 'foo'

        module Arj
          module SampleModule
            # @!method failing
            #   See: {Arj::Relation#failing}
            # @!method queue
            #   See: {Arj::Relation#queue}
            # @!method executable
            #   See: {Arj::Relation#executable}
            # @!method todo
            #   See: {Arj::Relation#todo}
          end
        end
      RUBY
    end
    let(:file) do
      tmp = Tempfile.new('sample_module.rb')
      tmp.write(original_file_content)
      tmp.rewind
      tmp
    end
    let(:module_name) { 'Arj::SampleModule' }
    let(:source) { Arj::Relation }
    let(:methods) { Arj::Relation::QUERY_METHODS }
    let(:format_string) { 'See: {%<class>s#%<method>s}' }

    after do
      file.close
      file.unlink
    end

    context 'when content is up to date' do
      it 'does not change the content' do
        subject
        expect(file.read).to eq(original_file_content)
      end
    end

    context 'when content is not up to date' do
      let(:methods) { Arj::Relation::QUERY_METHODS - [:todo] }

      let(:expected_file_content) do
        <<~RUBY
          require 'foo'

          module Arj
            module SampleModule
              # @!method failing
              #   See: {Arj::Relation#failing}
              # @!method queue
              #   See: {Arj::Relation#queue}
              # @!method executable
              #   See: {Arj::Relation#executable}
            end
          end
        RUBY
      end

      it 'changes the content' do
        subject
        expect(file.read).to eq(expected_file_content)
      end
    end

    context 'when source does not define method' do
      let(:methods) { Arj::Relation::QUERY_METHODS + [:some_method] }

      it 'raises' do
        expect { subject }.to raise_error(StandardError, 'undocumented methods: [:some_method]')
      end
    end
  end

  context '.generate_all' do
    subject { described_class.generate_all }

    context 'when content is up to date' do
      it 'does not change arj_relation.rb' do
        expect { subject }.not_to(change { File.read('lib/arj/documentation/arj_relation.rb') })
      end

      it 'does not change active_record_relation.rb' do
        expect { subject }.not_to(change { File.read('lib/arj/documentation/active_record_relation.rb') })
      end

      it 'does not change enumerable.rb' do
        expect { subject }.not_to(change { File.read('lib/arj/documentation/enumerable.rb') })
      end
    end
  end
end
