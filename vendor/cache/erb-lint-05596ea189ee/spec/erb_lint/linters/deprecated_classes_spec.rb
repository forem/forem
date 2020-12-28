# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Linters::DeprecatedClasses do
  let(:linter_config) do
    described_class.config_schema.new(
      rule_set: rule_set
    )
  end

  let(:file_loader) { ERBLint::FileLoader.new('.') }
  let(:linter) { described_class.new(file_loader, linter_config) }
  let(:processed_source) { ERBLint::ProcessedSource.new('file.rb', file) }
  subject { linter.offenses }
  before { linter.run(processed_source) }

  context 'when the rule set is empty' do
    let(:rule_set) { [] }

    context 'when the file is empty' do
      let(:file) { '' }

      it 'does not report any offense' do
        expect(subject).to(eq([]))
      end
    end

    context 'when the file has classes in start tags' do
      let(:file) { <<~FILE }
        <div class="a">
          Content
        </div>
      FILE

      it 'does not report any offenses' do
        expect(subject).to(eq([]))
      end
    end
  end

  context 'when the rule set has deprecated classes' do
    deprecated_set_1 = ['abc', 'foo-bar--darker']
    suggestion_1 = 'Suggestion1'
    deprecated_set_2 = ['expr', 'expr[\w-]*']
    suggestion_2 = 'Suggestion2'

    let(:rule_set) do
      [
        {
          'deprecated' => deprecated_set_1,
          'suggestion' => suggestion_1,
        },
        {
          'deprecated' => deprecated_set_2,
          'suggestion' => suggestion_2,
        },
      ]
    end

    context 'when the file is empty' do
      let(:file) { '' }

      it 'does not report any offenses' do
        expect(subject).to(eq([]))
      end
    end

    context 'when the file contains no classes from either set' do
      let(:file) { <<~FILE }
        <div class="unkown">
          Content
        </div>
      FILE

      it 'does not report any offenses' do
        expect(subject).to(eq([]))
      end
    end

    context 'when the file contains a class from set 1' do
      let(:file) { <<~FILE }
        <div class="#{deprecated_set_1.first}">
          Content
        </div>
      FILE

      it 'reports 1 offense' do
        expect(subject.size).to(eq(1))
      end

      it 'reports an offense with message containing suggestion 1' do
        expect(subject.first.message).to(include(suggestion_1))
      end
    end

    context 'when the file contains nested html content' do
      let(:file) { <<~FILE }
        <script type="text/html">
          <div class="#{deprecated_set_1.first}">
            Content
          </div>
        </script>
      FILE

      it 'reports 1 offense' do
        expect(subject.size).to(eq(1))
      end

      it 'reports an offense with message containing suggestion 1' do
        expect(subject.first.message).to(include(suggestion_1))
      end

      it 'reports an offense with position range that is adjusted in the nested context' do
        expect(subject.first.source_range.begin_pos).to(eq(28))
        expect(subject.first.source_range.end_pos).to(eq(45))
        expect(subject.first.source_range.source).to(eq("<div class=\"abc\">"))
      end
    end

    context 'when the file contains both classes from set 1' do
      context 'when both classes are on the same tag' do
        let(:file) { <<~FILE }
          <div class="#{deprecated_set_1[0]} #{deprecated_set_1[1]}">
            Content
          </div>
        FILE

        it 'reports 2 offenses' do
          expect(subject.size).to(eq(2))
        end

        it 'reports offenses with messages containing suggestion 1' do
          expect(subject[0].message).to(include(suggestion_1))
          expect(subject[1].message).to(include(suggestion_1))
        end
      end

      context 'when both classes are on different tags' do
        let(:file) { <<~FILE }
          <div class="#{deprecated_set_1[0]}">
            <a href="#" class="#{deprecated_set_1[1]}"></a>
          </div>
        FILE

        it 'reports 2 offenses' do
          expect(subject.size).to(eq(2))
        end

        it 'reports offenses with messages containing suggestion 1' do
          expect(subject[0].message).to(include(suggestion_1))
          expect(subject[1].message).to(include(suggestion_1))
        end
      end
    end

    context 'when the file contains a class matching both expressions from set 2' do
      let(:file) { <<~FILE }
        <div class="expr">
          Content
        </div>
      FILE

      it 'reports 2 offenses' do
        expect(subject.size).to(eq(2))
      end

      it 'reports offenses with messages containing suggestion 2' do
        expect(subject[0].message).to(include(suggestion_2))
        expect(subject[1].message).to(include(suggestion_2))
      end
    end

    context 'when an addendum is present' do
      let(:linter_config) do
        described_class.config_schema.new(
          rule_set: rule_set,
          addendum: addendum,
        )
      end
      let(:addendum) { 'Addendum badoo ba!' }

      context 'when the file is empty' do
        let(:file) { '' }

        it 'does not report any offenses' do
          expect(subject).to(eq([]))
        end
      end

      context 'when the file contains a class from a deprecated set' do
        let(:file) { <<~FILE }
          <div class="#{deprecated_set_1.first}">
            Content
          </div>
        FILE

        it 'reports 1 offense' do
          expect(subject.size).to(eq(1))
        end

        it 'reports an offense with its message ending with the addendum' do
          expect(subject.first.message).to(end_with(addendum))
        end
      end
    end

    context 'when an addendum is absent' do
      let(:linter_config) do
        described_class.config_schema.new(
          rule_set: rule_set
        )
      end

      context 'when the file is empty' do
        let(:file) { '' }

        it 'does not report any offenses' do
          expect(subject).to(eq([]))
        end
      end

      context 'when the file contains a class from a deprecated set' do
        let(:file) { <<~FILE }
          <div class="#{deprecated_set_1.first}">
            Content
          </div>
        FILE

        it 'reports 1 offense' do
          expect(subject.size).to(eq(1))
        end

        it 'reports an offense with its message ending with the suggestion' do
          expect(subject.first.message).to(end_with(suggestion_1))
        end
      end
    end

    context 'when invalid attributes have really long names' do
      let(:file) { <<~FILE }
        <div superlongpotentialattributename"small">
      FILE

      it 'does not report any offenses' do
        expect(subject).to(eq([]))
      end
    end
  end
end
