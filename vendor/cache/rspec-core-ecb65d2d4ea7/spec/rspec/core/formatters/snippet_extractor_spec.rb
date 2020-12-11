require 'rspec/core/formatters/snippet_extractor'

module RSpec::Core::Formatters
  RSpec.describe SnippetExtractor do
    subject(:expression_lines) do
      SnippetExtractor.extract_expression_lines_at(file_path, line_number, max_line_count)
    end

    let(:file_path) do
      location[0]
    end

    let(:line_number) do
      location[1]
    end

    let(:location) do
      error.backtrace.find do |line|
        !line.include?('do_something_fail') && line.match(%r{\A(.+?):(\d+)})
      end

      location = Regexp.last_match.captures
      location[1] = location[1].to_i
      location
    end

    let(:max_line_count) do
      nil
    end

    let(:error) do
      begin
        source
      rescue => error
        error
      else
        raise 'No error has been raised'
      end
    end

    # We use this helper method to raise an error while allowing any arguments,
    #
    # Note that MRI 1.9 strangely reports backtrace line as the first argument line instead of the
    # beginning of the method invocation. It's not SnippetExtractor's fault and even affects to the
    # simple single line extraction.
    def do_something_fail(*)
      raise
    end

    def another_expression(*)
    end

    context 'when the given file does not exist' do
      let(:file_path) do
        '/non-existent.rb'
      end

      let(:line_number) do
        1
      end

      it 'raises NoSuchFileError' do
        expect { expression_lines }.to raise_error(SnippetExtractor::NoSuchFileError)
      end
    end

    context 'when the given line does not exist in the file' do
      let(:file_path) do
        __FILE__
      end

      let(:line_number) do
        99999
      end

      it 'raises NoSuchLineError' do
        expect { expression_lines }.to raise_error(SnippetExtractor::NoSuchLineError)
      end
    end

    context 'when the expression fits into a single line' do
      let(:source) do
        do_something_fail :foo
      end

      it 'returns the line' do
        expect(expression_lines).to eq([
          '        do_something_fail :foo'
        ])
      end
    end

    context 'in Ripper supported environment', :if => RSpec::Support::RubyFeatures.ripper_supported? do
      context 'when the expression spans multiple lines' do
        let(:source) do
          do_something_fail :foo,
                            :bar
        end

        it 'returns the lines' do
          expect(expression_lines).to eq([
            '          do_something_fail :foo,',
            '                            :bar'
          ])
        end
      end

      context 'when the expression ends with ")"-only line' do
        let(:source) do
          do_something_fail(:foo
          )
        end

        it 'returns all the lines' do
          expect(expression_lines).to eq([
            '          do_something_fail(:foo',
            '          )'
          ])
        end
      end

      context 'when the expression ends with "}"-only line' do
        let(:source) do
          do_something_fail {
          }
        end

        it 'returns all the lines' do
          expect(expression_lines).to eq([
            '          do_something_fail {',
            '          }'
          ])
        end
      end

      context 'when the expression ends with "]"-only line' do
        let(:source) do
          do_something_fail :foo, [
          ]
        end

        it 'returns all the lines' do
          expect(expression_lines).to eq([
            '          do_something_fail :foo, [',
            '          ]'
          ])
        end
      end

      context 'when the expression contains do-end block and ends with "end"-only line' do
        let(:source) do
          do_something_fail do
          end
        end

        it 'returns all the lines' do
          expect(expression_lines).to eq([
            '          do_something_fail do',
            '          end'
          ])
        end
      end

      argument_error_points_invoker = RSpec::Support::Ruby.jruby? && !RUBY_VERSION.start_with?('1.8.')
      context 'when the expression is a method definition and ends with "end"-only line', :unless => argument_error_points_invoker do
        let(:source) do
          obj = Object.new

          def obj.foo(arg)
            p arg
          end

          obj.foo
        end

        it 'returns all the lines' do
          expect(expression_lines).to eq([
            '          def obj.foo(arg)',
            '            p arg',
            '          end'
          ])
        end
      end

      context "when the expression ends with multiple paren-only lines of same type" do
        let(:source) do
          do_something_fail(:foo, (:bar
            )
          )
        end

        it 'returns all the lines' do
          expect(expression_lines).to eq([
            '          do_something_fail(:foo, (:bar',
            '            )',
            '          )'
          ])
        end
      end

      context "when the expression includes paren and heredoc pairs as non-nested structure" do
        let(:source) do
          do_something_fail(<<-END)
            foo
          END
        end

        it 'returns all the lines' do
          expect(expression_lines).to eq([
            '          do_something_fail(<<-END)',
            '            foo',
            '          END'
          ])
        end
      end

      context 'when the expression spans lines after the closing paren line' do
        let(:source) do
          do_something_fail(:foo
          ).
          do_something_chain
        end

        # [:program,
        #  [[:call,
        #    [:method_add_arg, [:fcall, [:@ident, "do_something_fail", [1, 10]]], [:arg_paren, nil]],
        #    :".",
        #    [:@ident, "do_something_chain", [3, 10]]]]]

        it 'returns all the lines' do
          expect(expression_lines).to eq([
            '          do_something_fail(:foo',
            '          ).',
            '          do_something_chain'
          ])
        end
      end

      context "when the expression's final line includes the same type of opening paren of another multiline expression" do
        let(:source) do
          do_something_fail(:foo
          ); another_expression(:bar
          )
        end

        it 'ignores another expression' do
          expect(expression_lines).to eq([
            '          do_something_fail(:foo',
            '          ); another_expression(:bar'
          ])
        end
      end

      context "when the expression's first line includes a closing paren of another multiline expression" do
        let(:source) do
          another_expression(:bar
          ); do_something_fail(:foo
          )
        end

        it 'ignores another expression' do
          expect(expression_lines).to eq([
            '          ); do_something_fail(:foo',
            '          )'
          ])
        end
      end

      context 'when no expression exists at the line' do
        let(:file_path) do
          __FILE__
        end

        let(:line_number) do
          __LINE__ + 1
          # The failure happened here without expression
        end

        it 'returns the line by falling back to the simple single line extraction' do
          expect(expression_lines).to eq([
            '          # The failure happened here without expression'
          ])
        end
      end

      context 'when Ripper cannot parse the source (which can happen on JRuby -- see jruby/jruby#2427)', :isolated_directory do
        let(:file_path) { 'invalid_source.rb' }

        let(:line_number) { 1 }

        let(:source) { <<-EOS.gsub(/^ +\|/, '') }
          |expect("some string").to include(
          |  "some", "string"
          |]
        EOS

        before do
          File.open(file_path, 'w') { |file| file.write(source) }
        end

        it 'returns the line by falling back to the simple single line extraction' do
          expect(expression_lines).to eq([
            'expect("some string").to include('
          ])
        end
      end

      context 'when max line count is given' do
        let(:max_line_count) do
          2
        end

        let(:source) do
          do_something_fail "line1", [
            "line2",
            "line3"
          ]
        end

        it 'returns the lines without exceeding the given count' do
          expect(expression_lines).to eq([
            '          do_something_fail "line1", [',
            '            "line2",'
          ])
        end
      end

      context 'when max line count is 1' do
        let(:max_line_count) do
          1
        end

        let(:source) do
          do_something_fail "line1", [
            "line2",
            "line3"
          ]
        end

        before do
          RSpec.reset # Clear source cache
        end

        it 'returns the line without parsing the source for efficiency' do
          require 'ripper'
          expect(Ripper).not_to receive(:sexp)
          expect(expression_lines).to eq([
            '          do_something_fail "line1", ['
          ])
        end
      end
    end

    context 'in Ripper unsupported environment', :unless => RSpec::Support::RubyFeatures.ripper_supported? do
      context 'when the expression spans multiple lines' do
        let(:source) do
          do_something_fail :foo,
                            :bar
        end

        it 'returns only the first line' do
          expect(expression_lines).to eq([
            '          do_something_fail :foo,'
          ])
        end
      end
    end
  end
end
