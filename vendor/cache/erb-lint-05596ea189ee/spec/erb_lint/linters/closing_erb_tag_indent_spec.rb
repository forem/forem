# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Linters::ClosingErbTagIndent do
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

    context 'when tag is correct' do
      let(:file) { "<% foo %>" }
      it { expect(subject).to(eq([])) }
    end

    context 'when tag starts and ends with a newline' do
      let(:file) { <<~ERB }
        <%
          foo
        %>
      ERB
      it { expect(subject).to(eq([])) }
    end

    context 'when tag start and end are misaligned' do
      let(:file) { <<~ERB }
        <%
          foo
            %>
      ERB
      it do
        expect(subject).to(eq([
          build_offense(9..12, "Indent `%>` on column 0 to match start of tag."),
        ]))
      end
    end

    context 'when tag start and end are misaligned with extra newlines' do
      let(:file) { <<~ERB }
        x <%
          foo


            %>
      ERB
      it do
        expect(subject).to(eq([
          build_offense(13..16, "Indent `%>` on column 2 to match start of tag."),
        ]))
      end
    end

    context 'when tag starts with newline but ends on same line' do
      let(:file) { <<~ERB }
        <%
          foo %>
      ERB
      it do
        expect(subject).to(eq([
          build_offense(8..8, "Insert newline before `%>` to match start of tag."),
        ]))
      end
    end

    context 'when tag starts on same line but ends with newline' do
      let(:file) { <<~ERB }
        <% foo
        %>
      ERB
      it do
        expect(subject).to(eq([
          build_offense(6..6, "Remove newline before `%>` to match start of tag."),
        ]))
      end
    end
  end

  describe 'autocorrect' do
    subject { corrected_content }

    context 'when tag is correct' do
      let(:file) { "<% foo %>" }
      it { expect(subject).to(eq(file)) }
    end

    context 'when tag starts and ends with a newline' do
      let(:file) { <<~ERB }
        <%
          foo
        %>
      ERB
      it { expect(subject).to(eq(file)) }
    end

    context 'when tag start and end are misaligned' do
      let(:file) { <<~ERB }
        <%
          foo
            %>
      ERB
      it { expect(subject).to(eq(<<~ERB)) }
        <%
          foo
        %>
      ERB
    end

    context 'when tag start and end are misaligned with extra newlines' do
      let(:file) { <<~ERB }
        <div><%
          foo

                %>
      ERB
      it { expect(subject).to(eq(<<~ERB)) }
        <div><%
          foo

             %>
      ERB
    end

    context 'when tag starts with newline but ends on same line' do
      let(:file) { <<~ERB }
        <%
          foo %>
      ERB
      it { expect(subject).to(eq(<<~ERB)) }
        <%
          foo
        %>
      ERB
    end

    context 'when tag starts on same line but ends with newline' do
      let(:file) { <<~ERB }
        <% foo
        %>
      ERB
      it { expect(subject).to(eq(<<~ERB)) }
        <% foo %>
      ERB
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
