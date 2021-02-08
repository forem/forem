# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Linters::TrailingWhitespace do
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

    context 'when no trailing space is present' do
      let(:file) { "a perfect line\n" }
      it { expect(subject).to(eq([])) }
    end

    context 'when a trailing space is present at end of file' do
      let(:file) { "a not so perfect line    " }
      it do
        expect(subject).to(eq([
          build_offense(21..24, "Extra whitespace detected at end of line."),
        ]))
      end
    end

    context 'when a trailing space before newline' do
      let(:file) { "a not so perfect line    \n" }
      it do
        expect(subject).to(eq([
          build_offense(21..24, "Extra whitespace detected at end of line."),
        ]))
      end
    end

    context 'when tabs are present' do
      let(:file) { "a not so perfect line  \t\r\t  \n" }
      it do
        expect(subject).to(eq([
          build_offense(21..27, "Extra whitespace detected at end of line."),
        ]))
      end
    end

    context 'when spaces are alone on a line' do
      let(:file) { "a line\n       \nanother line\n" }
      it do
        expect(subject).to(eq([
          build_offense(7..13, "Extra whitespace detected at end of line."),
        ]))
      end
    end
  end

  describe 'autocorrect' do
    subject { corrected_content }

    context 'when no trailing space is present' do
      let(:file) { "a perfect line\n" }
      it { expect(subject).to(eq(file)) }
    end

    context 'when a trailing space is present at end of file' do
      let(:file) { "a not so perfect line    " }
      it { expect(subject).to(eq("a not so perfect line")) }
    end

    context 'when a trailing space before newline' do
      let(:file) { "a not so perfect line    \n" }
      it { expect(subject).to(eq("a not so perfect line\n")) }
    end

    context 'when tabs are present' do
      let(:file) { "a not so perfect line  \t\r\t  \n" }
      it { expect(subject).to(eq("a not so perfect line\n")) }
    end

    context 'when spaces are alone on a line' do
      let(:file) { "a line\n\nanother line\n" }
      it { expect(subject).to(eq(file)) }
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
