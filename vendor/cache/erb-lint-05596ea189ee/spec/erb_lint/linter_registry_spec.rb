# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::LinterRegistry do
  let(:custom_directory) { File.expand_path('../fixtures/linters', __FILE__) }

  context 'when including the LinterRegistry module' do
    after do
      described_class.clear
    end

    it 'adds the linter to the set of registered linters' do
      expect do
        class FakeLinter < ERBLint::Linter
          include ERBLint::LinterRegistry
        end
      end.to(change { described_class.linters.count }.by(1))
    end

    it 'adds custom linters to the set of registered linters' do
      stub_const('ERBLint::LinterRegistry::CUSTOM_LINTERS_DIR', custom_directory)

      expect(described_class.linters).to(include(ERBLint::Linters::CustomLinter))
    end
  end

  describe '.load_custom_linters' do
    it 'adds the custom linter to the set of registered linters' do
      expect(described_class).to(receive(:require)
        .with(File.join(custom_directory, 'custom_linter.rb')).once)
      described_class.load_custom_linters(custom_directory)
    end
  end
end
