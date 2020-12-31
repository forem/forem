# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Linters::Rubocop do
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
  let(:corrector) { ERBLint::Corrector.new(processed_source, offenses) }
  let(:corrected_content) { corrector.corrected_content }
  let(:nested_config) { nil }
  let(:inherit_from_filename) { 'custom_rubocop.yml' }
  subject { offenses }
  before do
    allow(file_loader).to(receive(:yaml).with(inherit_from_filename).and_return(nested_config))
  end
  before { linter.run(processed_source) }

  context 'config is valid when rubocop_config is not explicitly provided' do
    let(:linter_config) do
      described_class.config_schema.new(only: %w(NotALinter))
    end
    let(:file) { <<~FILE }
      <% not_banned_method %>
    FILE
    it { expect(subject).to(eq([])) }
  end

  context 'when rubocop finds no offenses' do
    let(:file) { <<~FILE }
      <% not_banned_method %>
    FILE

    it { expect(subject).to(eq([])) }
  end

  context 'when rubocop encounters a erb comment' do
    let(:file) { <<~FILE }
      <%# this whole erb block is a comment
        auto_correct_me
      %>
    FILE

    it { expect(subject).to(eq([])) }
  end

  context 'when rubocop encounters a ruby comment' do
    let(:file) { <<~FILE }
      <%
        # only this line is a comment
        auto_correct_me
      %>
    FILE

    it { expect(subject).to(eq([arbitrary_error_message(37..51)])) }
    it { expect(subject.first.source_range.source).to(eq("auto_correct_me")) }
  end

  context 'when rubocop finds offenses in ruby statements' do
    let(:file) { <<~FILE }
      <% auto_correct_me %>
    FILE

    it { expect(subject).to(eq([arbitrary_error_message(3..17)])) }
    it { expect(subject.first.source_range.source).to(eq("auto_correct_me")) }

    context 'when autocorrecting' do
      subject { corrected_content }

      it { expect(subject).to(eq("<% safe_method %>\n")) }
    end
  end

  context 'when rubocop finds offenses in ruby expressions' do
    let(:file) { <<~FILE }
      <%= auto_correct_me %>
    FILE

    it { expect(subject).to(eq([arbitrary_error_message(4..18)])) }

    context 'when autocorrecting' do
      subject { corrected_content }

      it { expect(subject).to(eq("<%= safe_method %>\n")) }
    end

    context 'when autocorrecting from rubocop cops' do
      let(:file) { <<~FILE }
        <%= 'should_be_double_quoted' %>
      FILE

      let(:linter_config) do
        described_class.config_schema.new(
          only: ['Style/StringLiterals'],
          rubocop_config: {
            AllCops: {
              TargetRubyVersion: '2.7',
            },
            'Style/StringLiterals': {
              EnforcedStyle: 'double_quotes',
              Enabled: true,
            },
          },
        )
      end

      subject { corrected_content }

      it { expect(subject).to(eq(%(<%= "should_be_double_quoted" %>\n))) }
    end
  end

  context 'when multiple offenses are found in the same block' do
    let(:file) { <<~FILE }
      <%
      auto_correct_me(:foo)
      auto_correct_me(:bar)
      auto_correct_me(:baz)
      %>
    FILE

    it 'finds offenses' do
      expect(subject).to(eq([
        arbitrary_error_message(3..17),
        arbitrary_error_message(25..39),
        arbitrary_error_message(47..61),
      ]))
    end

    context 'can autocorrect individual offenses' do
      let(:corrector) { ERBLint::Corrector.new(processed_source, [offenses.first]) }
      subject { corrected_content }

      it { expect(subject).to(eq(<<~FILE)) }
        <%
        safe_method(:foo)
        auto_correct_me(:bar)
        auto_correct_me(:baz)
        %>
      FILE
    end
  end

  context 'partial ruby statements are ignored' do
    let(:file) { <<~FILE }
      <% if auto_correct_me %>
        foo
      <% end %>
    FILE

    it { expect(subject).to(eq([])) }
  end

  context 'statements with partial block expression is processed' do
    let(:file) { <<~FILE }
      <% auto_correct_me.each do %>
        foo
      <% end %>
    FILE

    it { expect(subject).to(eq([arbitrary_error_message(3..17)])) }

    context 'when autocorrecting' do
      subject { corrected_content }

      it { expect(subject).to(eq(<<~FILE)) }
        <% safe_method.each do %>
          foo
        <% end %>
      FILE
    end
  end

  context 'line numbers take into account both html and erb newlines' do
    let(:file) { <<~FILE }
      <div>
        <%
          if foo?
            auto_correct_me
          end
        %>
      </div>
    FILE

    it { expect(subject).to(eq([arbitrary_error_message(29..43)])) }
    it { expect(subject.first.source_range.source).to(eq("auto_correct_me")) }
  end

  context 'supports loading nested config' do
    let(:linter_config) do
      described_class.config_schema.new(
        only: ['ErbLint/AutoCorrectCop'],
        rubocop_config: {
          inherit_from: inherit_from_filename,
          AllCops: {
            TargetRubyVersion: '2.7',
          },
        },
      )
    end

    let(:nested_config) do
      {
        'ErbLint/AutoCorrectCop': {
          'Enabled': false,
        },
      }.deep_stringify_keys
    end

    context 'rules from nested config are merged' do
      let(:file) { <<~FILE }
        <% auto_correct_me %>
      FILE

      it { expect(subject).to(eq([])) }
    end
  end

  context 'code is aligned to the column matching start of ruby code' do
    let(:linter_config) do
      described_class.config_schema.new(
        only: ['Layout/ArgumentAlignment'],
        rubocop_config: {
          AllCops: {
            TargetRubyVersion: '2.5',
          },
          'Layout/ArgumentAlignment': {
            Enabled: true,
            EnforcedStyle: 'with_fixed_indentation',
            SupportedStyles: %w(with_first_parameter with_fixed_indentation),
            IndentationWidth: nil,
          },
        },
      )
    end

    context 'when alignment is correct' do
      let(:file) { <<~FILE }
        <% ui_helper :foo,
             checked: true %>
      FILE

      it { expect(subject).to(eq([])) }
    end

    context 'when alignment is incorrect' do
      let(:file) { <<~FILE }
        <% ui_helper :foo,
              checked: true %>
      FILE

      it do
        expect(subject.size).to(eq(1))
        expect(subject[0].source_range.begin_pos).to(eq(25))
        expect(subject[0].source_range.end_pos).to(eq(38))
        expect(subject[0].source_range.source).to(eq("checked: true"))
        expect(subject[0].line_range).to(eq(2..2))
        expect(subject[0].message).to(\
          eq("Layout/ArgumentAlignment: Use one level of indentation for "\
             "arguments following the first line of a multi-line method call.")
        )
      end
    end

    context 'correct alignment with html preceeding erb' do
      let(:file) { <<~FILE }
        <div><a><br><% ui_helper :foo,
                         checked: true %>
      FILE

      it { expect(subject).to(eq([])) }
    end
  end

  context 'autocorrected and not autocorrected offenses are aligned' do
    let(:file) { <<~FILE }
      <% dont_auto_correct_me(auto_correct_me(dont_auto_correct_me)) %>
    FILE

    it { expect(corrected_content).to(eq("<% dont_auto_correct_me(safe_method(dont_auto_correct_me)) %>\n")) }
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
