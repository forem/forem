# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::LinterConfig do
  context 'with custom config' do
    let(:linter_config) { described_class.new(config_hash) }

    describe '#to_hash' do
      subject { linter_config.to_hash }

      context 'with empty hash' do
        let(:config_hash) { {} }

        it 'returns default config' do
          expect(subject).to(eq("enabled" => false, "exclude" => []))
        end
      end

      context 'with custom data' do
        let(:config_hash) { { foo: true } }

        it { expect { subject }.to(raise_error(described_class::Error, "Given key is not allowed: foo")) }
      end
    end

    describe '#[]' do
      subject { linter_config[key] }

      class CustomConfig < described_class
        property :foo
      end
      let(:linter_config) { CustomConfig.new(config_hash) }

      context 'with empty hash' do
        let(:config_hash) { {} }
        let(:key) { 'foo' }

        it { expect(subject).to(eq(nil)) }
      end

      context 'with custom data' do
        let(:config_hash) { { foo: 'custom value' } }
        let(:key) { 'foo' }

        it { expect(subject).to(eq('custom value')) }
      end

      context 'with string data and symbol key' do
        let(:config_hash) { { 'foo' => 'custom value' } }
        let(:key) { :foo }

        it { expect(subject).to(eq('custom value')) }
      end

      context 'with unknown key' do
        let(:config_hash) { {} }
        let(:key) { 'bogus' }

        it { expect { subject }.to(raise_error(described_class::Error, "No such property: bogus")) }
      end
    end

    describe '#enabled?' do
      subject { linter_config.enabled? }

      context 'when enabled is true' do
        let(:config_hash) { { enabled: true } }
        it { expect(subject).to(eq(true)) }
      end

      context 'when enabled is false' do
        let(:config_hash) { { enabled: false } }
        it { expect(subject).to(eq(false)) }
      end

      context 'when enabled key is missing' do
        let(:config_hash) { {} }
        it { expect(subject).to(eq(false)) }
      end

      context 'when enabled key is not true or false' do
        let(:config_hash) { { enabled: 42 } }
        it do
          expect { subject }.to(\
            raise_error(
              described_class::Error,
              "ERBLint::LinterConfig does not accept 42 as value for the property enabled. Only accepts: [true, false]"
            )
          )
        end
      end

      context 'when enabled key is nil' do
        let(:config_hash) { { enabled: nil } }
        it { expect(subject).to(eq(nil)) }
      end
    end

    describe '#excludes_file?' do
      context 'when glob matches' do
        let(:config_hash) { { exclude: ['vendor/**/*'] } }
        subject { linter_config.excludes_file?('vendor/gem/foo.rb') }
        it { expect(subject).to(eq(true)) }
      end

      context 'when glob does not match' do
        let(:config_hash) { { exclude: ['vendor/**/*'] } }
        subject { linter_config.excludes_file?('app/foo.rb') }
        it { expect(subject).to(eq(false)) }
      end
    end
  end
end
