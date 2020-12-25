# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Linters::SpaceAroundErbTag do
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
      let(:file) { "<% foo %>" }
      it { expect(subject).to(eq([])) }
    end

    context 'for escaped erb tag' do
      let(:file) { "this is text <%%=text %> not erb\n" }
      it { expect(subject).to(eq([])) }
    end

    context 'for erb comment' do
      let(:file) { "this is text <%#comment %> not erb\n" }
      it { expect(subject).to(eq([])) }
    end

    context 'when tag starts with a newline' do
      let(:file) { <<~ERB }
        <%
          foo
        %>
      ERB
      it { expect(subject).to(eq([])) }
    end

    context 'when tag contains extra spaces and newlines' do
      let(:file) { "<%  \n  foo  \n %>" }
      it { expect(subject).to(eq([])) }
    end

    context 'when tag contains extra spaces and multiple newlines' do
      let(:file) { "<%  \n\n\n  foo  \n\n\n %>" }
      it do
        expect(subject).to(eq([
          build_offense(2..8, "Use 1 newline after `<%` instead of 3."),
          build_offense(12..17, "Use 1 newline before `%>` instead of 3."),
        ]))
      end
    end

    context 'when space is missing on the left of statement' do
      let(:file) { "<%foo %>" }
      it do
        expect(subject).to(eq([
          build_offense(2..1, "Use 1 space after `<%` instead of 0 space."),
        ]))
      end
    end

    context 'when space is missing on the left of expression' do
      let(:file) { "<%=foo %>" }
      it do
        expect(subject).to(eq([
          build_offense(3..2, "Use 1 space after `<%=` instead of 0 space."),
        ]))
      end
    end

    context 'when space is missing on the left of statement with trim' do
      let(:file) { "<%-foo %>" }
      it do
        expect(subject).to(eq([
          build_offense(3..2, "Use 1 space after `<%-` instead of 0 space."),
        ]))
      end
    end

    context 'when more than 1 space on the left' do
      let(:file) { "<%  foo %>" }
      it do
        expect(subject).to(eq([
          build_offense(2..3, "Use 1 space after `<%` instead of 2 spaces."),
        ]))
      end
    end

    context 'when space is missing on the right' do
      let(:file) { "<% foo%>" }
      it do
        expect(subject).to(eq([
          build_offense(6..5, "Use 1 space before `%>` instead of 0 space."),
        ]))
      end
    end

    context 'when space is missing on the right with trim' do
      let(:file) { "<% foo-%>" }
      it do
        expect(subject).to(eq([
          build_offense(6..5, "Use 1 space before `-%>` instead of 0 space."),
        ]))
      end
    end

    context 'when more than 1 space on the right' do
      let(:file) { "<% foo   %>" }
      it do
        expect(subject).to(eq([
          build_offense(6..8, "Use 1 space before `%>` instead of 3 space."),
        ]))
      end
    end
  end

  describe 'autocorrect' do
    subject { corrected_content }

    context 'when space is correct' do
      let(:file) { "<% foo %>" }
      it { expect(subject).to(eq(file)) }
    end

    context 'when tag starts with a newline' do
      let(:file) { <<~ERB }
        <%
          foo
        %>
      ERB
      it { expect(subject).to(eq(file)) }
    end

    context 'when tag contains extra spaces and newlines' do
      let(:file) { "<%  \n  foo  \n %>" }
      it { expect(subject).to(eq(file)) }
    end

    context 'when tag contains extra spaces and multiple newlines' do
      let(:file) { "<%  \n\n\n  foo  \n\n\n %>" }
      it { expect(subject).to(eq("<%  \n  foo  \n %>")) }
    end

    context 'when space is missing on the left of statement' do
      let(:file) { "<%foo %>" }
      it { expect(subject).to(eq("<% foo %>")) }
    end

    context 'when space is missing on the left of expression' do
      let(:file) { "<%=foo %>" }
      it { expect(subject).to(eq("<%= foo %>")) }
    end

    context 'when space is missing on the left of statement with trim' do
      let(:file) { "<%-foo %>" }
      it { expect(subject).to(eq("<%- foo %>")) }
    end

    context 'when more than 1 space on the left' do
      let(:file) { "<%  foo %>" }
      it { expect(subject).to(eq("<% foo %>")) }
    end

    context 'when space is missing on the right' do
      let(:file) { "<% foo%>" }
      it { expect(subject).to(eq("<% foo %>")) }
    end

    context 'when space is missing on the right with trim' do
      let(:file) { "<% foo-%>" }
      it { expect(subject).to(eq("<% foo -%>")) }
    end

    context 'when more than 1 space on the right' do
      let(:file) { "<% foo   %>" }
      it { expect(subject).to(eq("<% foo %>")) }
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
