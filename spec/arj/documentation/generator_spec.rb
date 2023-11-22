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
          module SampleDoc
            # @!method bar
            #   See: {Arj::SampleModule#bar}
            # @!method foo
            #   See: {Arj::SampleModule#foo}
          end
        end
      RUBY
    end
    let(:file) do
      tmp = Tempfile.new('sample_doc.rb')
      tmp.write(original_file_content)
      tmp.rewind
      tmp
    end
    let(:module_name) { 'Arj::SampleDoc' }
    let(:source) do
      stub_const('Arj::SampleModule', Class.new)
      Arj::SampleModule.class_eval do
        def foo; end

        def bar; end
      end
      Arj::SampleModule
    end
    let(:methods) { %i[foo bar] }
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
      let(:methods) { [:foo] }

      let(:expected_file_content) do
        <<~RUBY
          require 'foo'

          module Arj
            module SampleDoc
              # @!method foo
              #   See: {Arj::SampleModule#foo}
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
      let(:methods) { %i[foo bar some_method] }

      it 'raises' do
        expect { subject }.to raise_error(StandardError, 'undocumented methods: [:some_method]')
      end
    end
  end

  context '.generate_all' do
    subject { described_class.generate_all }

    context 'when content is up to date' do
      it 'does not change arj_relation.rb' do
        expect { subject }.not_to(change { File.read('lib/arj/documentation/arj_record.rb') })
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
