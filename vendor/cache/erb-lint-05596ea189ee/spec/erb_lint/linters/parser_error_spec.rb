# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Linters::ParserErrors do
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

    context 'when file is valid' do
      let(:file) { "<a>" }
      it { expect(subject).to(eq([])) }
    end

    context 'when file is invalid' do
      let(:file) { "<>" }
      it do
        expect(subject).to(eq([
          build_offense(1..1, "expected '/' or tag name (at >)"),
        ]))
      end
    end

    context 'escaped erb is ignored' do
      let(:file) { "<%%= erb %>" }
      it do
        expect(subject).to(eq([]))
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
