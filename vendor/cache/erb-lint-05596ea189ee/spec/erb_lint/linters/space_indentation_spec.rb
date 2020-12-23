# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Linters::SpaceIndentation do
  let(:linter_config) { described_class.config_schema.new }

  let(:file_loader) { ERBLint::FileLoader.new('.') }
  let(:linter) { described_class.new(file_loader, linter_config) }
  let(:processed_source) { ERBLint::ProcessedSource.new('file.rb', file) }
  let(:offenses) { linter.offenses }
  let(:corrector) { ERBLint::Corrector.new(processed_source, offenses) }
  let(:corrected_content) { corrector.corrected_content }
  before { linter.run(processed_source) }

  describe 'offenses' do
    subject { offenses }

    context 'no indentation present' do
      let(:file) { "this is a line" }
      it { expect(subject).to(eq([])) }
    end

    context 'space indentation present' do
      let(:file) { "   this is a line\n   another line\n" }
      it { expect(subject).to(eq([])) }
    end

    context 'tab indentation' do
      let(:file) { "\t\tthis is a line\n\t\tanother line\n" }
      it do
        expect(subject).to(eq([
          build_offense(0..1, "Indent with spaces instead of tabs."),
          build_offense(17..18, "Indent with spaces instead of tabs."),
        ]))
      end
    end

    context 'tab and spaces indentation' do
      let(:file) { "  \t    this is a line\n  \t  another line\n" }
      it do
        expect(subject).to(eq([
          build_offense(0..6, "Indent with spaces instead of tabs."),
          build_offense(22..26, "Indent with spaces instead of tabs."),
        ]))
      end
    end
  end

  describe 'autocorrect' do
    subject { corrected_content }

    context 'no indentation present' do
      let(:file) { "this is a line" }
      it { expect(subject).to(eq(file)) }
    end

    context 'space indentation present' do
      let(:file) { "   this is a line\n   another line\n" }
      it { expect(subject).to(eq(file)) }
    end

    context 'tab indentation' do
      let(:file) { "\tthis is a line\n\tanother line\n" }

      context 'with default tab width' do
        it { expect(subject).to(eq("  this is a line\n  another line\n")) }
      end

      context 'with custom tab width' do
        let(:linter_config) { described_class.config_schema.new(tab_width: 4) }
        it { expect(subject).to(eq("    this is a line\n    another line\n")) }
      end
    end

    context 'tab and spaces indentation' do
      let(:file) { "  \t    this is a line\n  \t  another line\n" }
      it { expect(subject).to(eq("        this is a line\n      another line\n")) }
    end
  end

  private

  def build_offense(range, message)
    ERBLint::Offense.new(
      linter,
      processed_source.to_source_range(range),
      message
    )
  end
end
