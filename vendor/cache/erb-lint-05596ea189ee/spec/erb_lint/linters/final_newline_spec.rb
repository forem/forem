# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Linters::FinalNewline do
  let(:linter_config) { described_class.config_schema.new(present: present) }

  let(:file_loader) { ERBLint::FileLoader.new('.') }
  let(:linter) { described_class.new(file_loader, linter_config) }
  let(:processed_source) { ERBLint::ProcessedSource.new('file.rb', file) }
  let(:offenses) { linter.offenses }
  let(:corrector) { ERBLint::Corrector.new(processed_source, offenses) }
  let(:corrected_content) { corrector.corrected_content }
  subject { offenses }
  before { linter.run(processed_source) }

  context 'when trailing newline is preferred' do
    let(:present) { true }

    context 'when the file is empty' do
      let(:file) { '' }

      it 'does not report any offenses' do
        expect(subject).to(eq([]))
      end
    end

    context 'when the file ends with a newline' do
      let(:file) { "<div id=\"a\">\nContent\n</div>\n" }

      it 'does not report any errors' do
        expect(subject).to(eq([]))
      end
    end

    context 'when the file ends with multiple newlines' do
      let(:file) { "<div id=\"a\">\nContent\n</div>\n\n\n" }

      it 'reports 1 offense' do
        expect(subject.size).to(eq(1))
      end

      it 'the offense range is set to an empty range after the last character of the file' do
        expect(subject.first.source_range.begin_pos).to(eq(28))
        expect(subject.first.source_range.end_pos).to(eq(30))
        expect(subject.first.source_range.source).to(eq("\n\n"))
        expect(subject.first.message).to(eq(\
          "Remove multiple trailing newline at the end of the file."
        ))
      end

      it 'autocorrects' do
        expect(corrected_content).to(eq("<div id=\"a\">\nContent\n</div>\n"))
      end
    end

    context 'when the file does not end with a newline' do
      let(:file) { "<div id=\"a\">\nContent\n</div>" }

      it 'reports 1 offense' do
        expect(subject.size).to(eq(1))
      end

      it 'reports an offense on the last line' do
        expect(subject.first.line_range).to(eq(3..3))
      end

      it 'the offense range is set to an empty range after the last character of the file' do
        expect(subject.first.source_range.begin_pos).to(eq(27))
        expect(subject.first.source_range.end_pos).to(eq(27))
        expect(subject.first.source_range.source).to(eq(""))
      end

      it 'autocorrects' do
        expect(corrected_content).to(eq("<div id=\"a\">\nContent\n</div>\n"))
      end
    end
  end

  context 'when no trailing newline is preferred' do
    let(:present) { false }

    context 'when the file is empty' do
      let(:file) { '' }

      it 'does not report any offenses' do
        expect(subject).to(eq([]))
      end
    end

    context 'when the file ends with a newline' do
      let(:file) { "<div id=\"a\">\nContent\n</div>\n" }

      it 'reports 1 offense' do
        expect(subject.size).to(eq(1))
      end

      it 'reports meaningful message' do
        expect(subject.first.message).to(eq('Remove 1 trailing newline at the end of the file.'))
      end

      it 'reports an offense on the last line' do
        expect(subject.first.line_range).to(eq(3..4))
      end

      it 'the offense range is set to the newline character' do
        expect(subject.first.source_range.begin_pos).to(eq(27))
        expect(subject.first.source_range.end_pos).to(eq(28))
        expect(subject.first.source_range.source).to(eq("\n"))
      end

      it 'autocorrects' do
        expect(corrected_content).to(eq("<div id=\"a\">\nContent\n</div>"))
      end
    end

    context 'when the file ends with multiple newlines' do
      let(:file) { "foo\n\n\n\n" }

      it 'the offense range includes all newline characters' do
        expect(subject.first.source_range.begin_pos).to(eq(3))
        expect(subject.first.source_range.end_pos).to(eq(7))
        expect(subject.first.source_range.source).to(eq("\n\n\n\n"))
      end

      it 'reports meaningful message' do
        expect(subject.first.message).to(eq('Remove 4 trailing newline at the end of the file.'))
      end

      it 'autocorrects' do
        expect(corrected_content).to(eq("foo"))
      end
    end

    context 'when the file does not end with a newline' do
      let(:file) { "<div id=\"a\">\nContent\n</div>" }

      it 'does not report any offenses' do
        expect(subject).to(eq([]))
      end
    end
  end

  context 'when trailing newline preference is not stated' do
    let(:linter_config) { described_class.config_schema.new }

    context 'when the file is empty' do
      let(:file) { '' }

      it 'does not report any offenses' do
        expect(subject).to(eq([]))
      end
    end

    context 'when the file ends with a newline' do
      let(:file) { "<div id=\"a\">\nContent\n</div>\n" }

      it 'does not report any offenses' do
        expect(subject).to(eq([]))
      end
    end

    context 'when the file does not end with a newline' do
      let(:file) { "<div id=\"a\">\nContent\n</div>" }

      it 'reports 1 offense' do
        expect(subject.size).to(eq(1))
      end

      it 'reports an offense on the last line' do
        expect(subject.first.line_range).to(eq(3..3))
      end
    end
  end
end
