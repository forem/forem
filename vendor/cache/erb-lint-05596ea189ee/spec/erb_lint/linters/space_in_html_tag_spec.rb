# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Linters::SpaceInHtmlTag do
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

    context 'when space is correct' do
      context 'plain opening tag' do
        let(:file) { "<div>" }
        it { expect(subject).to(eq([])) }
      end

      context 'self-closing tag without attributes' do
        let(:file) { "<img />" }
        it { expect(subject).to(eq([])) }
      end

      context 'closing tag' do
        let(:file) { "</div>" }
        it { expect(subject).to(eq([])) }
      end

      context 'tag with no name' do
        let(:file) { "</>" }
        it { expect(subject).to(eq([])) }
      end

      context 'empty tag' do
        let(:file) { "<>" }
        it { expect(subject).to(eq([])) }
      end

      context 'plain tag with attribute' do
        let(:file) { '<div class="foo">' }
        it { expect(subject).to(eq([])) }
      end

      context 'self-closing tag with attribute' do
        let(:file) { '<input class="foo" />' }
        it { expect(subject).to(eq([])) }
      end

      context 'between attributes' do
        let(:file) { '<input class="foo" name="bar" />' }
        it { expect(subject).to(eq([])) }
      end

      context 'multi-line tag' do
        let(:file) { <<~HTML }
          <input
            type="password"
            class="foo" />
        HTML
        it { expect(subject).to(eq([])) }
      end

      context 'tag with erb' do
        let(:file) { <<~HTML }
          <input <%= attributes %> />
        HTML
        it { expect(subject).to(eq([])) }
      end

      context 'multi-line tag with erb' do
        let(:file) { <<~HTML }
          <input
            type="password"
            <%= attributes %>
            class="foo" />
        HTML
        it { expect(subject).to(eq([])) }
      end
    end

    context 'when no space should be present' do
      context 'after name' do
        let(:file) { "<div   >" }
        it do
          expect(subject).to(eq([
            build_offense(4..6, "Extra space detected where there should be no space."),
          ]))
        end
      end

      context 'before name' do
        let(:file) { "<   div>" }
        it do
          expect(subject).to(eq([
            build_offense(1..3, "Extra space detected where there should be no space."),
          ]))
        end
      end

      context 'before start solidus' do
        let(:file) { "<   /div>" }
        it do
          expect(subject).to(eq([
            build_offense(1..3, "Extra space detected where there should be no space."),
          ]))
        end
      end

      context 'after start solidus' do
        let(:file) { "</   div>" }
        it do
          expect(subject).to(eq([
            build_offense(2..4, "Extra space detected where there should be no space."),
          ]))
        end
      end

      context 'after end solidus' do
        let(:file) { "<div /   >" }
        it do
          expect(subject).to(eq([
            build_offense(6..8, "Extra space detected where there should be no space."),
          ]))
        end
      end

      context 'between attribute name and equal' do
        let(:file) { "<div foo  ='bar'>" }
        it do
          expect(subject).to(eq([
            build_offense(8..9, "Extra space detected where there should be no space."),
          ]))
        end
      end

      context 'between attribute equal and value' do
        let(:file) { "<div foo=  'bar'>" }
        it do
          expect(subject).to(eq([
            build_offense(9..10, "Extra space detected where there should be no space."),
          ]))
        end
      end
    end

    context 'when space is missing' do
      context 'between attributes' do
        let(:file) { "<div foo='foo'bar='bar'>" }
        it do
          expect(subject).to(eq([
            build_offense(14..13, "No space detected where there should be "\
              "a single space."),
          ]))
        end
      end

      context 'between last attribute and solidus' do
        let(:file) { "<div foo='bar'/>" }
        it do
          expect(subject).to(eq([
            build_offense(14..13, "No space detected where there should be "\
              "a single space."),
          ]))
        end
      end

      context 'between name and solidus' do
        let(:file) { "<div/>" }
        it do
          expect(subject).to(eq([
            build_offense(4..3, "No space detected where there should be "\
              "a single space."),
          ]))
        end
      end
    end

    context 'when extra space is present' do
      context 'between name and end of tag' do
        let(:file) { "<div  >" }
        it do
          expect(subject).to(eq([
            build_offense(4..5, "Extra space detected where there should be no space."),
          ]))
        end
      end

      context 'between name and first attribute' do
        let(:file) { '<img   class="hide">' }
        it do
          expect(subject).to(eq([
            build_offense(4..6, "Extra space detected where there should be "\
              "a single space."),
          ]))
        end
      end

      context 'between name and end solidus' do
        let(:file) { "<br   />" }
        it do
          expect(subject).to(eq([
            build_offense(3..5, "Extra space detected where there should be "\
              "a single space."),
          ]))
        end
      end

      context 'between last attribute and solidus' do
        let(:file) { '<br class="hide"   />' }
        it do
          expect(subject).to(eq([
            build_offense(16..18, "Extra space detected where there should be "\
              "a single space."),
          ]))
        end
      end

      context 'between last attribute and end of tag' do
        let(:file) { '<img class="hide"    >' }
        it do
          expect(subject).to(eq([
            build_offense(17..20, "Extra space detected where there should be "\
              "no space."),
          ]))
        end
      end

      context 'between attributes' do
        let(:file) { "<div foo='foo'      bar='bar'>" }
        it do
          expect(subject).to(eq([
            build_offense(14..19, "Extra space detected where there should be "\
              "a single space."),
          ]))
        end
      end

      context 'extra newline between name and first attribute' do
        let(:file) { <<~HTML }
          <input

            type="password" />
        HTML
        it do
          expect(subject).to(eq([
            build_offense(6..9, "Extra space detected where there should be "\
              "a single space or a single line break."),
          ]))
        end
      end

      context 'extra newline between name and end of tag' do
        let(:file) { <<~HTML }
          <input

            />
        HTML
        it do
          expect(subject).to(eq([
            build_offense(6..9, "Extra space detected where there should be "\
              "a single space."),
          ]))
        end
      end

      context 'extra newline between attributes' do
        let(:file) { <<~HTML }
          <input
            type="password"

            class="foo" />
        HTML
        it do
          expect(subject).to(eq([
            build_offense(24..27, "Extra space detected where there should be "\
              "a single space or a single line break."),
          ]))
        end
      end

      context 'end solidus is on newline' do
        let(:file) { <<~HTML }
          <input
            type="password"
            class="foo"
            />
        HTML
        it do
          expect(subject).to(eq([
            build_offense(38..40, "Extra space detected where there should be "\
              "a single space."),
          ]))
        end
      end

      context 'end of tag is on newline' do
        let(:file) { <<~HTML }
          <input
            type="password"
            class="foo"
            >
        HTML
        it do
          expect(subject).to(eq([
            build_offense(38..40, "Extra space detected where there should be "\
              "no space."),
          ]))
        end
      end

      context 'non-space detected between name and attribute' do
        let(:file) { <<~HTML }
          <input/class="hide" />
        HTML
        it do
          expect(subject).to(eq([
            build_offense(6..6, 'Non-whitespace character(s) detected: "/".'),
          ]))
        end
      end

      context 'non-space detected between attribures' do
        let(:file) { <<~HTML }
          <input class="hide"/name="foo" />
        HTML
        it do
          expect(subject).to(eq([
            build_offense(19..19, 'Non-whitespace character(s) detected: "/".'),
          ]))
        end
      end
    end
  end

  describe 'autocorrect' do
    subject { corrected_content }

    context 'when space is correct' do
      context 'plain opening tag' do
        let(:file) { "<div>" }
        it { expect(subject).to(eq(file)) }
      end

      context 'self-closing tag without attributes' do
        let(:file) { "<img />" }
        it { expect(subject).to(eq(file)) }
      end

      context 'closing tag' do
        let(:file) { "</div>" }
        it { expect(subject).to(eq(file)) }
      end

      context 'tag with no name' do
        let(:file) { "</>" }
        it { expect(subject).to(eq(file)) }
      end

      context 'plain tag with attribute' do
        let(:file) { '<div class="foo">' }
        it { expect(subject).to(eq(file)) }
      end

      context 'self-closing tag with attribute' do
        let(:file) { '<input class="foo" />' }
        it { expect(subject).to(eq(file)) }
      end

      context 'between attributes' do
        let(:file) { '<input class="foo" name="bar" />' }
        it { expect(subject).to(eq(file)) }
      end

      context 'multi-line tag' do
        let(:file) { <<~HTML }
          <input
            type="password"
            class="foo" />
        HTML
        it { expect(subject).to(eq(file)) }
      end

      context 'escaped <%%= tag' do
        let(:file) { <<~ERB }
          <%- if options.stylesheet? -%>
            <%%= content_for :application_stylesheets, stylesheet_link_tag('application') %>
          <%- end -%>
        ERB
        it { expect(subject).to(eq(file)) }
      end
    end

    context 'when no space should be present' do
      context 'after name' do
        let(:file) { "<div   >" }
        it { expect(subject).to(eq("<div>")) }
      end

      context 'before name' do
        let(:file) { "<   div>" }
        it { expect(subject).to(eq("<div>")) }
      end

      context 'before start solidus' do
        let(:file) { "<   /div>" }
        it { expect(subject).to(eq("</div>")) }
      end

      context 'after start solidus' do
        let(:file) { "</   div>" }
        it { expect(subject).to(eq("</div>")) }
      end

      context 'after end solidus' do
        let(:file) { "<div/   >" }
        it { expect(subject).to(eq("<div />")) }
      end

      context 'between attribute name and equal' do
        let(:file) { "<div foo  ='bar'>" }
        it { expect(subject).to(eq("<div foo='bar'>")) }
      end

      context 'between attribute equal and value' do
        let(:file) { "<div foo=  'bar'>" }
        it { expect(subject).to(eq("<div foo='bar'>")) }
      end
    end

    context 'when space is missing' do
      context 'between attributes' do
        let(:file) { "<div foo='foo'bar='bar'>" }
        it { expect(subject).to(eq("<div foo='foo' bar='bar'>")) }
      end

      context 'between last attribute and solidus' do
        let(:file) { "<div foo='bar'/>" }
        it { expect(subject).to(eq("<div foo='bar' />")) }
      end

      context 'between name and solidus' do
        let(:file) { "<div/>" }
        it { expect(subject).to(eq("<div />")) }
      end
    end

    context 'when extra space is present' do
      context 'between name and end of tag' do
        let(:file) { "<div  >" }
        it { expect(subject).to(eq("<div>")) }
      end

      context 'between name and first attribute' do
        let(:file) { "<div  >" }
        it { expect(subject).to(eq("<div>")) }
      end

      context 'between name and first attribute' do
        let(:file) { '<img   class="hide">' }
        it { expect(subject).to(eq('<img class="hide">')) }
      end

      context 'between name and end solidus' do
        let(:file) { "<br   />" }
        it { expect(subject).to(eq("<br />")) }
      end

      context 'between last attribute and solidus' do
        let(:file) { '<br class="hide"   />' }
        it { expect(subject).to(eq('<br class="hide" />')) }
      end

      context 'between last attribute and end of tag' do
        let(:file) { '<img class="hide"    >' }
        it { expect(subject).to(eq('<img class="hide">')) }
      end

      context 'between attributes' do
        let(:file) { "<div foo='foo'      bar='bar'>" }
        it { expect(subject).to(eq("<div foo='foo' bar='bar'>")) }
      end

      context 'extra newline between name and first attribute' do
        let(:file) { <<~HTML }
          <input

            type="password" />
        HTML
        it { expect(subject).to(eq(<<~HTML)) }
          <input
            type="password" />
        HTML
      end

      context 'extra newline between name and end of tag' do
        let(:file) { <<~HTML }
          <input

            />
        HTML
        it { expect(subject).to(eq(<<~HTML)) }
          <input />
        HTML
      end

      context 'extra newline between attributes' do
        let(:file) { <<~HTML }
          <input
            type="password"

            class="foo" />
        HTML
        it { expect(subject).to(eq(<<~HTML)) }
          <input
            type="password"
            class="foo" />
        HTML
      end

      context 'end solidus is on newline' do
        let(:file) { <<~HTML }
          <input
            type="password"
            class="foo"
            />
        HTML
        it { expect(subject).to(eq(<<~HTML)) }
          <input
            type="password"
            class="foo" />
        HTML
      end

      context 'end of tag is on newline' do
        let(:file) { <<~HTML }
          <input
            type="password"
            class="foo"
            >
        HTML
        it { expect(subject).to(eq(<<~HTML)) }
          <input
            type="password"
            class="foo">
        HTML
      end

      context 'non-space detected between name and attribute' do
        let(:file) { <<~HTML }
          <input/class="hide" />
        HTML
        it { expect(subject).to(eq(<<~HTML)) }
          <input class="hide" />
        HTML
      end

      context 'non-space detected between attribures' do
        let(:file) { <<~HTML }
          <input class="hide"/name="foo" />
        HTML
        it { expect(subject).to(eq(<<~HTML)) }
          <input class="hide" name="foo" />
        HTML
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
