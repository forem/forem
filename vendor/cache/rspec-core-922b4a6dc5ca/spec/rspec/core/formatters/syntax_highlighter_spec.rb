require 'rspec/core/formatters/syntax_highlighter'

module RSpec::Core::Formatters
  RSpec.describe SyntaxHighlighter do
    let(:config)      { RSpec::Core::Configuration.new.tap { |config| config.color_mode = :on } }
    let(:highlighter) { SyntaxHighlighter.new(config)  }

    context "when CodeRay is available", :unless => RSpec::Support::OS.windows? do
      before { expect { require 'coderay' }.not_to raise_error }

      it 'highlights the syntax of the provided lines' do
        highlighted = highlighter.highlight(['[:ok, "ok"]'])
        expect(highlighted.size).to eq(1)
        expect(highlighted.first).to be_highlighted.and include(":ok")
      end

      it 'prefixes the each line with a reset escape code so it can be interpolated in a colored string without affecting the syntax highlighting of the snippet' do
        highlighted = highlighter.highlight(['a = 1', 'b = 2'])
        expect(highlighted).to all start_with("\e[0m")
      end

      it 'leaves leading spaces alone so it can be re-indented as needed without the leading reset code interfering' do
        highlighted = highlighter.highlight(['  a = 1', '  b = 2'])
        expect(highlighted).to all start_with("  \e[0m")
      end

      it 'returns the provided lines unmodified if color is disabled' do
        config.color_mode = :off
        expect(highlighter.highlight(['[:ok, "ok"]'])).to eq(['[:ok, "ok"]'])
      end

      it 'dynamically adjusts to changing color config' do
        config.color_mode = :off
        expect(highlighter.highlight(['[:ok, "ok"]']).first).not_to be_highlighted
        config.color_mode = :on
        expect(highlighter.highlight(['[:ok, "ok"]']).first).to be_highlighted
        config.color_mode = :off
        expect(highlighter.highlight(['[:ok, "ok"]']).first).not_to be_highlighted
      end

      it "rescues coderay failures since we do not want a coderay error to be displayed instead of the user's error" do
        allow(CodeRay).to receive(:encode).and_raise(Exception.new "boom")
        lines = [":ok"]
        expect(highlighter.highlight(lines)).to eq(lines)
      end

      it "highlights core RSpec keyword-like methods" do
        highlighted_terms = find_highlighted_terms_in <<-EOS
          describe stuff do
            before { }
            after { }
            around { }
            let(stuff) { }
            subject { }
            context do
              it stuff do
                expect(thing).to foo
                allow(thing).to foo
              end
              example { }
              specify { }
            end
          end
        EOS

        expect(highlighted_terms).to match_array %w[
          describe context
          it specify
          before after around
          let subject
          expect allow
          do end
        ]
      end

      it "does not blow up if the coderay constant we update with our keywords is missing" do
        hide_const("CodeRay::Scanners::Ruby::Patterns::IDENT_KIND")
        expect(highlighter.highlight(['[:ok, "ok"]']).first).to be_highlighted
      end

      def find_highlighted_terms_in(code_snippet)
        lines = code_snippet.split("\n")
        highlighted = highlighter.highlight(lines)
        highlighted_terms = []

        highlighted.join("\n").scan(/\e\[[1-9]\dm(\w+)\e\[0m/) do |first_capture, _|
          highlighted_terms << first_capture
        end

        highlighted_terms.uniq
      end
    end

    context "when CodeRay is unavailable" do
      before do
        allow(highlighter).to receive(:require).with("coderay").and_raise(LoadError)
      end

      it 'does not highlight the syntax' do
        unhighlighted = highlighter.highlight(['[:ok, "ok"]'])
        expect(unhighlighted.size).to eq(1)
        expect(unhighlighted.first).not_to be_highlighted
      end

      it 'does not mutate the input array' do
        lines = ["a = 1", "b = 2"]
        expect { highlighter.highlight(lines) }.not_to change { lines }
      end

      it 'does not add the comment about coderay if the snippet is only one line as we do not want to convert it to multiline just for the comment' do
        expect(highlighter.highlight(["a = 1"])).to eq(["a = 1"])
      end

      it 'does not add the comment about coderay if given no lines' do
        expect(highlighter.highlight([])).to eq([])
      end

      it 'does not add the comment about coderay if color is disabled even when given a multiline snippet' do
        config.color_mode = :off
        lines = ["a = 1", "b = 2"]
        expect(highlighter.highlight(lines)).to eq(lines)
      end

    end

    def be_highlighted
      include("\e[31m")
    end

  end
end
