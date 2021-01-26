# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Linters::HardCodedString do
  let(:linter_options) { { i18n_load_path: 'test/load/path' } }
  let(:linter_config) do
    described_class.config_schema.new(linter_options)
  end
  let(:file_loader) { ERBLint::FileLoader.new('.') }
  let(:linter) { described_class.new(file_loader, linter_config) }
  let(:processed_source) { ERBLint::ProcessedSource.new('file.rb', file) }
  subject { linter.offenses }
  before { linter.run(processed_source) }

  context 'when file contains hard coded string' do
    let(:file) { <<~FILE }
      <span> Hello </span>
    FILE

    it { expect(subject).to(eq([untranslated_string_error(7..11, 'String not translated: Hello')])) }
  end

  context 'when file contains nested hard coded string' do
    let(:file) { <<~FILE }
      <span class="example">
        <div id="hero">
          <span id="cat"> Example </span>
        </div>
      </span>
    FILE

    it { expect(subject).to(eq([untranslated_string_error(61..67, 'String not translated: Example')])) }
  end

  context 'when file contains a mix of hard coded string and erb' do
    let(:file) { <<~FILE }
      <span><%= foo %> Example </span>
    FILE

    it { expect(subject).to(eq([untranslated_string_error(17..23, 'String not translated: Example')])) }
  end

  context 'when file contains hard coded string nested inside erb' do
    let(:file) { <<~FILE }
      <span>
        <% foo do %>
          <span> Example </span>
        <% end %>
      </span>
    FILE

    it { expect(subject).to(eq([untranslated_string_error(33..39, 'String not translated: Example')])) }
  end

  context 'when file contains multiple hard coded string' do
    let(:file) { <<~FILE }
      <span> Example </span>
      <span> Foo </span>
      <span> Test </span>
    FILE

    it 'find all offenses' do
      expect(subject).to(eq([
        untranslated_string_error(7..13, 'String not translated: Example'),
        untranslated_string_error(30..32, 'String not translated: Foo'),
        untranslated_string_error(49..52, 'String not translated: Test'),
      ]))
    end
  end

  context 'when file does not contain any hard coded string' do
    let(:file) { <<~FILE }
      <span class="example">
        <div id="hero">
          <span id="cat"> <%= t(:hello) %> </span>
        </div>
      </span>
    FILE

    it { expect(subject).to(eq([])) }
  end

  context 'when file contains blacklisted extraction' do
    let(:file) { <<~FILE }
      &nbsp;
    FILE

    it { expect(subject).to(eq([])) }
  end

  context 'when file contains irrelevant hard coded string' do
    let(:file) { <<~FILE }
      <span class="example">
        <% discounted_by %>%


      </span>
    FILE

    it 'does not add offense' do
      expect(subject).to(eq([]))
    end
  end

  context 'when file contains hard coded string inside javascript' do
    let(:file) { <<~FILE }
      <script type="text/template">
        const TEMPLATE = `
          <div class="example" data-modal-backdrop>
            <span> Hardcoded String </span>
          </div>`;
      </script>
    FILE

    it { expect(subject).to(eq([])) }
  end

  context 'when file contains hard coded string inside style' do
    let(:file) { <<~FILE }
      <style>
        p {
          background: white;
        }
      </style>
    FILE

    it { expect(subject).to(eq([])) }
  end

  %w(xmp iframe noembed noframes listing).each do |tag|
    context "when file contains hard coded string inside #{tag}" do
      let(:file) { <<~FILE }
        <#{tag}>
          hardcoded string
        </#{tag}>
      FILE

      it { expect(subject).to(eq([])) }
    end
  end

  context 'when file contains hard coded string following a javascript block' do
    let(:file) { <<~FILE }
      <script type="text/template">
        const TEMPLATE = `
          <div class="example" data-modal-backdrop>
            <span> Hardcoded String </span>
          </div>`;
      </script>
      Example
    FILE

    it { expect(subject).to(eq([untranslated_string_error(158..164, "String not translated: Example")])) }
  end

  context 'when file contains multiple chunks of hardcoded strings' do
    let(:file) { <<~FILE }
      <div>
        Foo <%= bar %> Foo2 <% bar %> Foo3
      </div>
    FILE

    it do
      expected = [
        untranslated_string_error(8..10, "String not translated: Foo"),
        untranslated_string_error(23..26, "String not translated: Foo2"),
        untranslated_string_error(38..41, "String not translated: Foo3"),
      ]

      expect(subject).to(eq(expected))
    end
  end

  context 'when file contains multiple hardcoded strings that spans on multiple lines' do
    let(:file) { <<~FILE }
      <div>
        Foo
        John
        Albert
        Smith
        <%= test %>
      </div>
    FILE

    it 'creates a new offense for each' do
      expected = [
        untranslated_string_error(8..10, "String not translated: Foo"),
        untranslated_string_error(14..17, "String not translated: John"),
        untranslated_string_error(21..26, "String not translated: Albert"),
        untranslated_string_error(30..34, "String not translated: Smith"),
      ]

      expect(subject).to(eq(expected))
    end
  end

  context 'with corrector and load_path' do
    let(:corrector_file) do
      Tempfile.new(['my_class', '.rb']).tap do |f|
        f.write(<<~EOM)
          class I18nCorrector
            attr_reader :node

            def initialize(node, filename, i18n_load_path, range)
            end

            def autocorrect(tag_start:, tag_end:)
              ->(corrector) do
                node
              end
            end
          end
        EOM
        f.rewind
      end
    end

    let(:translation_file) do
      Tempfile.new(['en', '.yml']).tap do |f|
        f.write(<<~EOM)
          ---
        EOM
        f.rewind
      end
    end

    after(:each) do
      corrector_file.unlink
      corrector_file.close
      translation_file.unlink
      translation_file.close
    end

    let(:linter_options) do
      { corrector: { path: corrector_file.path, name: 'I18nCorrector', i18n_load_path: translation_file.path } }
    end

    let(:file) { <<~FILE }
      <span> Hello </span>
    FILE

    it 'require the corrector' do
      offense = untranslated_string_error(7..11, 'String not translated: Hello')
      linter.autocorrect(processed_source, offense)

      expect(defined?(I18nCorrector)).to(eq('constant'))
    end

    context 'without i18n load path' do
      let(:linter_options) do
        { corrector: { path: corrector_file.path, name: 'I18nCorrector' } }
      end

      it 'rescues the MissingI18nLoadPath error when no load path options is passed' do
        offense = untranslated_string_error(7..11, 'String not translated: Hello')

        expect(linter.autocorrect(processed_source, offense)).to(eq(nil))
      end
    end

    context 'without corrector' do
      let(:linter_options) { {} }

      it 'rescue the MissingCorrector error when no corrector option is passed' do
        offense = untranslated_string_error(7..11, 'String not translated: Hello')

        expect(linter.autocorrect(processed_source, offense)).to(eq(nil))
      end
    end

    context 'can not constanize the class' do
      let(:linter_options) do
        { corrector: { path: corrector_file.path, i18n_load_path: translation_file.path, name: 'UnknownClass' } }
      end

      it 'does not continue the auto correction when the class passed is not whitelisted' do
        offense = untranslated_string_error(7..11, 'String not translated: Hello')

        error = ERBLint::Linters::HardCodedString::ForbiddenCorrector
        expect { linter.autocorrect(processed_source, offense) }.to(raise_error(error))
      end
    end
  end

  private

  def untranslated_string_error(range, string)
    ERBLint::Offense.new(
      linter,
      processed_source.to_source_range(range),
      string
    )
  end
end
