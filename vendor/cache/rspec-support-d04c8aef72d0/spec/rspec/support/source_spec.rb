require 'rspec/support/source'

module RSpec::Support
  RSpec.describe Source, :if => RSpec::Support::RubyFeatures.ripper_supported? do
    subject(:source) do
      Source.new(source_string)
    end

    let(:source_string) { <<-END.gsub(/^ +\|/, '') }
      |2.times do
      |  puts :foo
      |end
    END

    # [:program,
    #  [[:method_add_block,
    #    [:call, [:@int, "2", [1, 0]], :".", [:@ident, "times", [1, 2]]],
    #    [:do_block,
    #     nil,
    #     [[:command,
    #       [:@ident, "puts", [2, 2]],
    #       [:args_add_block,
    #        [[:symbol_literal, [:symbol, [:@ident, "foo", [2, 8]]]]],
    #        false]]]]]]]

    describe '.from_file', :isolated_directory do
      subject(:source) do
        Source.from_file(path)
      end

      let(:path) do
        'source.rb'
      end

      before do
        File.open(path, 'w') { |file| file.write(source_string) }
      end

      it 'returns a Source with the absolute path' do
        expect(source.lines.first).to eq('2.times do')
        expect(source.path).not_to eq(path)
        expect(source.path).to end_with(path)
      end

      it 'continues to work if File.read is stubbed' do
        allow(::File).to receive(:read).and_raise
        expect(source.lines.first).to eq('2.times do')
      end
    end

    describe '#lines' do
      it 'returns an array of lines without linefeed' do
        expect(source.lines).to eq([
          '2.times do',
          '  puts :foo',
          'end'
        ])
      end

      it 'returns an array of lines no matter the encoding' do
        source_string << "\xAE"
        encoded_string = source_string.force_encoding('US-ASCII')
        expect(Source.new(encoded_string).lines).to eq([
          '2.times do',
          '  puts :foo',
          'end',
          '?',
        ])
      end
    end

    describe '#ast' do
      it 'returns a root node' do
        expect(source.ast).to have_attributes(:type => :program)
      end
    end

    describe '#tokens' do
      it 'returns an array of tokens' do
        expect(source.tokens).to all be_a(Source::Token)
      end
    end

    describe '#nodes_by_line_number' do
      it 'returns a hash containing nodes for each line number' do
        expect(source.nodes_by_line_number).to match(
          1 =>
            if RUBY_VERSION >= '2.6.0'
              [
                an_object_having_attributes(:type => :@int),
                an_object_having_attributes(:type => :@period),
                an_object_having_attributes(:type => :@ident)
              ]
            else
              [
                an_object_having_attributes(:type => :@int),
                an_object_having_attributes(:type => :@ident)
              ]
            end,
          2 => [
            an_object_having_attributes(:type => :@ident),
            an_object_having_attributes(:type => :@ident)
          ]
        )

        expect(source.nodes_by_line_number[0]).to be_empty
      end
    end

    describe '#tokens_by_line_number' do
      it 'returns a hash containing tokens for each line number' do
        expect(source.tokens_by_line_number).to match(
          1 => [
            an_object_having_attributes(:type => :on_int),
            an_object_having_attributes(:type => :on_period),
            an_object_having_attributes(:type => :on_ident),
            an_object_having_attributes(:type => :on_sp),
            an_object_having_attributes(:type => :on_kw),
            an_object_having_attributes(:type => :on_ignored_nl)
          ],
          2 => [
            an_object_having_attributes(:type => :on_sp),
            an_object_having_attributes(:type => :on_ident),
            an_object_having_attributes(:type => :on_sp),
            an_object_having_attributes(:type => :on_symbeg),
            an_object_having_attributes(:type => :on_ident),
            an_object_having_attributes(:type => :on_nl)
          ],
          3 => [
            an_object_having_attributes(:type => :on_kw),
            an_object_having_attributes(:type => :on_nl)
          ]
        )

        expect(source.tokens_by_line_number[0]).to be_empty
      end
    end

    describe '#inspect' do
      it 'returns a string including class name and file path' do
        expect(source.inspect).to start_with('#<RSpec::Support::Source (string)>')
      end
    end
  end
end
