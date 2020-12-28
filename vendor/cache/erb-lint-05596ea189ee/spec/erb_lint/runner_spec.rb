# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Runner do
  let(:file_loader) { ERBLint::FileLoader.new('.') }
  let(:runner) { described_class.new(file_loader, config) }

  before do
    allow(ERBLint::LinterRegistry).to(receive(:linters)
      .and_return([ERBLint::Linters::FakeLinter1,
                   ERBLint::Linters::FakeLinter2,
                   ERBLint::Linters::FinalNewline]))
  end

  module ERBLint
    module Linters
      class FakeLinter1 < Linter
        def run(processed_source)
          add_offense(processed_source.to_source_range(1..1), "#{self.class.name} error")
        end
      end

      class FakeLinter2 < FakeLinter1; end
    end
  end

  describe '#run' do
    let(:file) { 'DummyFileContent' }
    let(:filename) { 'somefolder/otherfolder/dummyfile.html.erb' }
    let(:processed_source) { ERBLint::ProcessedSource.new(filename, file) }
    before { runner.run(processed_source) }
    subject { runner.offenses }

    context 'when all linters are enabled' do
      let(:config) do
        ERBLint::RunnerConfig.new(
          linters: {
            'FakeLinter1' => { 'enabled' => true },
            'FakeLinter2' => { 'enabled' => true },
          }
        )
      end

      it 'returns each linter with their errors' do
        expect(subject.size).to(eq(2))
        expect(subject[0].linter.class).to(eq(ERBLint::Linters::FakeLinter1))
        expect(subject[0].message).to(eq("ERBLint::Linters::FakeLinter1 error"))
        expect(subject[1].linter.class).to(eq(ERBLint::Linters::FakeLinter2))
        expect(subject[1].message).to(eq("ERBLint::Linters::FakeLinter2 error"))
      end
    end

    context 'when only some linters are enabled' do
      let(:config) do
        ERBLint::RunnerConfig.new(
          linters: {
            'FakeLinter1' => { 'enabled' => true },
            'FakeLinter2' => { 'enabled' => false },
          }
        )
      end

      it 'returns only enabled linters with their errors' do
        expect(subject.size).to(eq(1))
        expect(subject[0].linter.class).to(eq(ERBLint::Linters::FakeLinter1))
        expect(subject[0].message).to(eq("ERBLint::Linters::FakeLinter1 error"))
      end
    end

    context 'when all linters are disabled' do
      let(:config) do
        ERBLint::RunnerConfig.new(
          linters: {
            'FakeLinter1' => { 'enabled' => false },
            'FakeLinter2' => { 'enabled' => false },
          }
        )
      end

      it 'returns no linters' do
        expect(subject).to(be_empty)
      end
    end

    context 'when all linters exclude the file' do
      let(:config) do
        ERBLint::RunnerConfig.new(
          linters: {
            'FakeLinter1' => { 'enabled' => true, 'exclude' => ['**/otherfolder/**'] },
            'FakeLinter2' => { 'enabled' => true, 'exclude' => ['somefolder/**.html.erb'] },
          }
        )
      end

      it 'returns no linters' do
        expect(subject).to(be_empty)
      end
    end

    context 'when the config has no linters' do
      let(:config) { ERBLint::RunnerConfig.new }

      it 'has all linters disabled' do
        expect(subject).to(eq([]))
      end
    end

    context 'when the config is nil' do
      let(:config) { nil }

      it 'returns default linters with their errors' do
        expect(subject.size).to(eq(1))
        expect(subject[0].linter.class).to(eq(ERBLint::Linters::FinalNewline))
        expect(subject[0].message).to(eq("Missing a trailing newline at the end of the file."))
      end
    end

    context 'clear_offenses clears offenses' do
      let(:config) do
        ERBLint::RunnerConfig.new(
          linters: {
            'FakeLinter1' => { 'enabled' => true },
            'FakeLinter2' => { 'enabled' => true },
          }
        )
      end

      it 'clears all offenses from the offenses ivar' do
        runner.clear_offenses
        expect(subject).to(eq([]))
      end
    end
  end
end
