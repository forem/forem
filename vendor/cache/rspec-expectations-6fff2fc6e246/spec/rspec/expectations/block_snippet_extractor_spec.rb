require 'rspec/expectations/block_snippet_extractor'

module RSpec::Expectations
  RSpec.describe BlockSnippetExtractor, :if => RSpec::Support::RubyFeatures.ripper_supported? do
    subject(:extractor) do
      BlockSnippetExtractor.new(proc_object, 'target_method')
    end

    let(:proc_object) do
      @proc_object
    end

    def target_method(*, &block)
      @proc_object = block
    end

    def another_method(*)
    end

    before do
      expression
    end

    describe '.try_extracting_single_line_body_of' do
      subject(:try_extracting_single_line_body) do
        BlockSnippetExtractor.try_extracting_single_line_body_of(proc_object, 'target_method')
      end

      context 'with a single line body block' do
        let(:expression) do
          target_method { 1.positive? }
        end

        it 'returns the body' do
          expect(try_extracting_single_line_body).to eq('1.positive?')
        end
      end

      context 'with a multiline body block' do
        let(:expression) do
          target_method do
            1.positive?
            2.negative?
          end
        end

        it 'returns nil' do
          expect(try_extracting_single_line_body).to be_nil
        end
      end

      context 'when the block snippet cannot be extracted due to ambiguity' do
        let(:expression) do
          target_method { 1.positive? }; dummy_object.target_method { 2.negative? }
        end

        let(:dummy_object) do
          double('dummy_object', :target_method => nil)
        end

        it 'returns nil' do
          expect(try_extracting_single_line_body).to be_nil
        end
      end
    end

    describe '#body_content_lines' do
      subject(:body_content_lines) do
        extractor.body_content_lines
      end

      context 'with `target_method {}`' do
        let(:expression) do
          target_method {}
        end

        it 'returns empty lines' do
          expect(body_content_lines).to eq([])
        end
      end

      context 'with `target_method { body }`' do
        let(:expression) do
          target_method { 1.positive? }
        end

        it 'returns the body content lines' do
          expect(body_content_lines).to eq(['1.positive?'])
        end
      end

      context 'with `target_method do body end`' do
        let(:expression) do
          target_method do 1.positive? end
        end

        it 'returns the body content lines' do
          expect(body_content_lines).to eq(['1.positive?'])
        end
      end

      context 'with `target_method { |arg1, arg2| body }`' do
        let(:expression) do
          target_method { |_arg1, _arg2| 1.positive? }
        end

        it 'returns the body content lines' do
          expect(body_content_lines).to eq(['1.positive?'])
        end
      end

      context 'with `target_method(:arg1, :arg2) { body }`' do
        let(:expression) do
          target_method(:arg1, :arg2) { 1.positive? }
        end

        it 'returns the body content lines' do
          expect(body_content_lines).to eq(['1.positive?'])
        end
      end

      context 'with `target_method(:arg1,:arg2){|arg1,arg2|body}`' do
        let(:expression) do
          target_method(:arg1, :arg2) { |_arg1, _arg2|1.positive? }
        end

        it 'returns the body content lines' do
          expect(body_content_lines).to eq(['1.positive?'])
        end
      end

      context 'with a multiline block containing a single line body' do
        let(:expression) do
          target_method do
            1.positive?
          end
        end

        it 'returns the body content lines' do
          expect(body_content_lines).to eq(['1.positive?'])
        end
      end

      context 'with a multiline body block' do
        let(:expression) do
          target_method do
            1.positive?
            2.negative?
          end
        end

        it 'returns the body content lines' do
          expect(body_content_lines).to eq([
            '1.positive?',
            '2.negative?'
          ])
        end
      end

      context 'with `target_method { { :key => "value" } }`' do
        let(:expression) do
          target_method { { :key => "value" } }
        end

        it 'does not confuse the hash curly with the block closer' do
          expect(body_content_lines).to eq(['{ :key => "value" }'])
        end
      end

      context 'with a do-end block containing another do-end block' do
        let(:expression) do
          target_method do
            2.times do |index|
              puts index
            end
          end
        end

        it 'does not confuse the inner `end` with the outer `end`' do
          expect(body_content_lines).to eq([
            '2.times do |index|',
            'puts index',
            'end'
          ])
        end
      end

      context "when there's another method invocation on the same line before the target" do
        let(:expression) do
          another_method { 2.negative? }; target_method { 1.positive? }
        end

        it 'correctly extracts the target snippet' do
          expect(body_content_lines).to eq(['1.positive?'])
        end
      end

      context "when there's another method invocation on the same line after the target" do
        let(:expression) do
          target_method { 1.positive? }; another_method { 2.negative? }
        end

        it 'correctly extracts the target snippet' do
          expect(body_content_lines).to eq(['1.positive?'])
        end
      end

      context "when there's another method invocation with the same name on the same line before the target" do
        let(:expression) do
          dummy_object.target_method { 2.negative? }; target_method { 1.positive? }
        end

        let(:dummy_object) do
          double('dummy_object', :target_method => nil)
        end

        it 'raises AmbiguousTargetError' do
          expect { body_content_lines }.to raise_error(BlockSnippetExtractor::AmbiguousTargetError)
        end
      end

      context "when there's another method invocation with the same name on the same line after the target" do
        let(:expression) do
          target_method { 1.positive? }; dummy_object.target_method { 2.negative? }
        end

        let(:dummy_object) do
          double('dummy_object', :target_method => nil)
        end

        it 'raises AmbiguousTargetError' do
          expect { body_content_lines }.to raise_error(BlockSnippetExtractor::AmbiguousTargetError)
        end
      end

      context "when there's another method invocation with the same name without block on the same line before the target" do
        let(:expression) do
          dummy_object.target_method; target_method { 1.positive? }
        end

        let(:dummy_object) do
          double('dummy_object', :target_method => nil)
        end

        it 'correctly extracts the target snippet' do
          expect(body_content_lines).to eq(['1.positive?'])
        end
      end

      context "when there's another method invocation with the same name without block on the same line after the target" do
        let(:expression) do
          target_method { 1.positive? }; dummy_object.target_method
        end

        let(:dummy_object) do
          double('dummy_object', :target_method => nil)
        end

        it 'correctly extracts the target snippet' do
          expect(body_content_lines).to eq(['1.positive?'])
        end
      end

      context 'when a hash is given as an argument' do
        let(:expression) do
          target_method({ :key => "value" }) { 1.positive? }
        end

        it 'correctly extracts the target snippet' do
          expect(body_content_lines).to eq(['1.positive?'])
        end
      end

      context 'when another method invocation with block is given as an argument' do
        let(:expression) do
          target_method(another_method { 2.negative? }) { 1.positive? }
        end

        it 'correctly extracts the target snippet' do
          expect(body_content_lines).to eq(['1.positive?'])
        end
      end

      context "when the block literal is described on different line with the method invocation" do
        let(:expression) do
          block = proc { 1.positive? }
          target_method(&block)
        end

        it 'raises TargetNotFoundError' do
          expect { body_content_lines }.to raise_error(BlockSnippetExtractor::TargetNotFoundError)
        end
      end

      context 'with &:symbol syntax' do
        let(:expression) do
          target_method(&:positive?)
        end

        it 'raises TargetNotFoundError' do
          expect { body_content_lines }.to raise_error(BlockSnippetExtractor::TargetNotFoundError)
        end
      end
    end
  end
end
