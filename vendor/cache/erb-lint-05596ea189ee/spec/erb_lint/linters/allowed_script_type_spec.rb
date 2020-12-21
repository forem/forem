# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Linters::AllowedScriptType do
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

    context 'when type is correct' do
      let(:file) { '<script type="text/javascript">' }
      it { expect(subject).to(eq([])) }
    end

    context 'when type is incorrect' do
      let(:file) { '<script type="text/yavascript">' }
      it do
        expect(subject).to(eq([
          build_offense(8..29,
            "Avoid using \"text/yavascript\" as type for `<script>` tag. "\
            "Must be one of: text/javascript (or no type attribute)."),
        ]))
      end
    end

    context 'when disallow_inline_scripts=true' do
      let(:linter_config) { described_class.config_schema.new(disallow_inline_scripts: true) }

      context 'with any script tag' do
        let(:file) { '<script>' }
        it do
          expect(subject).to(eq([
            build_offense(1..6,
              "Avoid using inline `<script>` tags altogether. "\
              "Instead, move javascript code into a static file."),
          ]))
        end
      end
    end

    context 'when allow_blank=true' do
      let(:linter_config) { described_class.config_schema.new(allow_blank: true) }

      context 'when type is absent' do
        let(:file) { '<script>' }
        it { expect(subject).to(eq([])) }
      end

      context 'when type value is missing' do
        let(:file) { '<script type>' }
        it { expect(subject).to(eq([])) }
      end

      context 'when type value is present but blank' do
        let(:file) { '<script type="">' }
        it 'is not valid' do
          expect(subject).to(eq([
            build_offense(8..14,
              "Avoid using \"\" as type for `<script>` tag. Must be one of: text/javascript (or no type attribute)."),
          ]))
        end
      end
    end

    context 'when allow_blank=false' do
      let(:linter_config) { described_class.config_schema.new(allow_blank: false) }

      context 'when type is blank' do
        let(:file) { '<script>' }
        it do
          expect(subject).to(eq([
            build_offense(1..6,
              "Missing a `type=\"text/javascript\"` attribute to `<script>` tag."),
          ]))
        end
      end

      context 'when type is empty' do
        let(:file) { '<script type>' }
        it do
          expect(subject).to(eq([
            build_offense(1..6,
              "Missing a `type=\"text/javascript\"` attribute to `<script>` tag."),
          ]))
        end
      end
    end
  end

  describe 'autocorrect' do
    subject { corrected_content }

    context 'file remains the same' do
      context 'when type is correct' do
        let(:file) { '<script type="text/javascript">' }
        it { expect(subject).to(eq(file)) }
      end

      context 'when type is incorrect' do
        let(:file) { '<script type="text/yavascript">' }
        it { expect(subject).to(eq(file)) }
      end

      context 'when allow_blank=true' do
        let(:linter_config) { described_class.config_schema.new(allow_blank: true) }

        context 'when type is blank' do
          let(:file) { '<script>' }
          it { expect(subject).to(eq(file)) }
        end

        context 'when type is empty' do
          let(:file) { '<script type>' }
          it { expect(subject).to(eq(file)) }
        end
      end
    end

    context 'file is autocorrected' do
      context 'when allow_blank=false' do
        let(:linter_config) { described_class.config_schema.new(allow_blank: false) }

        context 'when type is blank' do
          let(:file) { '<script>' }
          it { expect(subject).to(eq('<script type="text/javascript">')) }
        end

        context 'when type is empty' do
          let(:file) { '<script type>' }
          it { expect(subject).to(eq('<script type="text/javascript">')) }
        end
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
