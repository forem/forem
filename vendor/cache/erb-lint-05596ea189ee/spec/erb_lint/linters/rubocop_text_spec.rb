# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Linters::RubocopText do
  let(:linter_config) do
    described_class.config_schema.new(
      only: ['ErbLint/AutoCorrectCop'],
      rubocop_config: {
        require: [File.expand_path('../../fixtures/cops/auto_correct_cop', __FILE__)],
        AllCops: {
          TargetRubyVersion: '2.5',
        },
      },
    )
  end
  let(:file_loader) { ERBLint::FileLoader.new('.') }
  let(:linter) { described_class.new(file_loader, linter_config) }
  let(:processed_source) { ERBLint::ProcessedSource.new('file.rb', file) }
  let(:offenses) { linter.offenses }
  subject { offenses }
  before { linter.run(processed_source) }

  context 'when file does not contain any erb text node' do
    let(:file) { <<~FILE }
      <span class="<%= auto_correct_me %>"></span>
    FILE

    it { expect(subject).to(eq([])) }
  end

  context 'when rubocop find offenses inside erb text node' do
    let(:file) { <<~FILE }
      <span> <%= auto_correct_me %> </span>
    FILE

    it { expect(subject).to(eq([arbitrary_error_message(11..25)])) }
  end

  context 'when rubocop does not find offenses inside erb text node' do
    let(:file) { <<~FILE }
      <span> <%= not_banned_method %> </span>
    FILE

    it { expect(subject).to(eq([])) }
  end

  private

  def arbitrary_error_message(range)
    ERBLint::Offense.new(
      linter,
      processed_source.to_source_range(range),
      "ErbLint/AutoCorrectCop: An arbitrary rule has been violated."
    )
  end
end
