# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Linters::RightTrim do
  let(:linter_config) { described_class.config_schema.new(enforced_style: enforced_style) }

  let(:file_loader) { ERBLint::FileLoader.new('.') }
  let(:linter) { described_class.new(file_loader, linter_config) }
  let(:processed_source) { ERBLint::ProcessedSource.new('file.rb', file) }
  let(:offenses) { linter.offenses }
  let(:corrector) { ERBLint::Corrector.new(processed_source, offenses) }
  let(:corrected_content) { corrector.corrected_content }
  before { linter.run(processed_source) }

  describe 'offenses' do
    subject { offenses }

    context 'when enforced_style is -' do
      let(:enforced_style) { '-' }

      context 'when trim is correct' do
        let(:file) { "<% foo -%>" }
        it { expect(subject).to(eq([])) }
      end

      context 'when trim is incorrect' do
        let(:file) { "<% foo =%>" }
        it do
          expect(subject).to(eq([
            build_offense(7..7, "Prefer -%> instead of =%> for trimming on the right."),
          ]))
        end
      end

      context 'when no trim is present' do
        let(:file) { "<% foo %>" }
        it { expect(subject).to(eq([])) }
      end

      context 'when a call argument is present that is not a trim' do
        let(:file) { "<% foo 1%>" }
        it { expect(subject).to(eq([])) }
      end
    end

    context 'when enforced_style is =' do
      let(:enforced_style) { '=' }

      context 'when trim is correct' do
        let(:file) { "<% foo =%>" }
        it { expect(subject).to(eq([])) }
      end

      context 'when trim is incorrect' do
        let(:file) { "<% foo -%>" }
        it do
          expect(subject).to(eq([
            build_offense(7..7, "Prefer =%> instead of -%> for trimming on the right."),
          ]))
        end
      end

      context 'when no trim is present' do
        let(:file) { "<% foo %>" }
        it { expect(subject).to(eq([])) }
      end

      context 'when a call argument is present that is not a trim' do
        let(:file) { "<% foo 1%>" }
        it { expect(subject).to(eq([])) }
      end
    end
  end

  describe 'autocorrect' do
    subject { corrected_content }

    context 'when enforced_style is -' do
      let(:enforced_style) { '-' }

      context 'when trim is correct' do
        let(:file) { "<% foo -%>" }
        it { expect(subject).to(eq(file)) }
      end

      context 'when trim is incorrect' do
        let(:file) { "<% foo =%>" }
        it { expect(subject).to(eq("<% foo -%>")) }
      end

      context 'when no trim is present' do
        let(:file) { "<% foo %>" }
        it { expect(subject).to(eq(file)) }
      end

      context 'when a call argument is present that is not a trim' do
        let(:file) { "<% foo 1%>" }
        it { expect(subject).to(eq(file)) }
      end
    end

    context 'when enforced_style is =' do
      let(:enforced_style) { '=' }

      context 'when trim is correct' do
        let(:file) { "<% foo =%>" }
        it { expect(subject).to(eq(file)) }
      end

      context 'when trim is incorrect' do
        let(:file) { "<% foo -%>" }
        it { expect(subject).to(eq("<% foo =%>")) }
      end

      context 'when no trim is present' do
        let(:file) { "<% foo %>" }
        it { expect(subject).to(eq(file)) }
      end

      context 'when a call argument is present that is not a trim' do
        let(:file) { "<% foo 1%>" }
        it { expect(subject).to(eq(file)) }
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
