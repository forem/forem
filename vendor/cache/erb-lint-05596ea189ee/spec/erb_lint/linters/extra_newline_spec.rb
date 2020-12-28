# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Linters::ExtraNewline do
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

    context 'when no new line is present' do
      let(:file) { "this is a line" }
      it { expect(subject).to(eq([])) }
    end

    context 'when no blank lines are present' do
      let(:file) { <<~FILE }
        line 1
        line 2
        line 3
      FILE
      it { expect(subject).to(eq([])) }
    end

    context 'when a single blank line is present' do
      let(:file) { <<~FILE }
        line 1

        line 3
      FILE
      it { expect(subject).to(eq([])) }
    end

    context 'when two blank lines follow each other' do
      let(:file) { <<~FILE }
        line 1


        line 3
      FILE
      it do
        expect(subject).to(eq([
          build_offense(8..8, "Extra blank line detected."),
        ]))
      end
    end

    context 'when more than two newlines follow each other' do
      let(:file) { <<~FILE }
        line 1




        line 3
      FILE
      it do
        expect(subject).to(eq([
          build_offense(8..10, "Extra blank line detected."),
        ]))
      end
    end
  end

  describe 'autocorrect' do
    subject { corrected_content }

    context 'when no new line is present' do
      let(:file) { "this is a line" }
      it { expect(subject).to(eq(file)) }
    end

    context 'when single blank line present at end of file' do
      let(:file) { "this is a line\n\n" }
      it { expect(subject).to(eq(file)) }
    end

    context 'when multiple blank lines present at end of file' do
      let(:file) { "this is a line\n\n\n\n" }
      it { expect(subject).to(eq("this is a line\n\n")) }
    end

    context 'when no blank lines are present' do
      let(:file) { <<~FILE }
        line 1
        line 2
        line 3
      FILE
      it { expect(subject).to(eq(file)) }
    end

    context 'when a single blank line is present' do
      let(:file) { <<~FILE }
        line 1

        line 3
      FILE
      it { expect(subject).to(eq(file)) }
    end

    context 'when two blank lines follow each other' do
      let(:file) { <<~FILE }
        line 1


        line 3
      FILE
      it do
        expect(subject).to(eq(<<~FILE))
          line 1

          line 3
        FILE
      end
    end

    context 'when more than two newlines follow each other' do
      let(:file) { <<~FILE }
        line 1




        line 3
      FILE
      it do
        expect(subject).to(eq(<<~FILE))
          line 1

          line 3
        FILE
      end
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
