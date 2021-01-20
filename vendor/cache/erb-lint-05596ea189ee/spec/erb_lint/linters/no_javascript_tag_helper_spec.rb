# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Linters::NoJavascriptTagHelper do
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

    context 'usage of javascript_tag helper' do
      let(:file) { <<~FILE }
        <br />
        <%= javascript_tag do %>
      FILE

      it { expect(subject).to(eq([build_offense(7..30)])) }
    end

    context 'regression with <%%= syntax does not raise an exception' do
      let(:file) { <<~FILE }
        <%%= ma_tile do |tile| %>
          <%%= tile.image 'styleguide/toronto-stunning-sunset' %>
        <%% end %>
        <% end %>
      FILE

      it { expect(subject).to(eq([])) }
    end

    context 'no method calls in erb tag' do
      let(:file) { <<~FILE }
        <%= true %>
      FILE

      it { expect(subject).to(eq([])) }
    end
  end

  describe 'autocorrect' do
    subject { corrected_content }

    context 'with string argument' do
      let(:file) { <<~HTML }
        <%= javascript_tag("var myData = 1;") %>
      HTML

      it { expect(subject).to(eq(<<~HTML)) }
        <script>
        //<![CDATA[
        var myData = 1;
        //]]>
        </script>
      HTML
    end

    context 'with plain correction style' do
      let(:linter_config) { described_class.config_schema.new(correction_style: 'plain') }
      let(:file) { <<~HTML }
        <%= javascript_tag("var myData = 1;") %>
      HTML

      it { expect(subject).to(eq(<<~HTML)) }
        <script>var myData = 1;</script>
      HTML
    end

    context 'with string argument and options' do
      let(:file) { <<~HTML }
        <%= javascript_tag('var myData = 1;', defer: true) %>
      HTML

      it { expect(subject).to(eq(<<~HTML)) }
        <script defer="true">
        //<![CDATA[
        var myData = 1;
        //]]>
        </script>
      HTML
    end

    context 'with string argument and options and interpolations' do
      let(:file) { <<~HTML }
        <%= javascript_tag("var myData = \#{myData.to_json};", custom_attribute: "foo-\#{my_attribute}") %>
      HTML

      it { expect(subject).to(eq(<<~HTML)) }
        <script custom-attribute="foo-<%= my_attribute %>">
        //<![CDATA[
        var myData = <%== myData.to_json %>;
        //]]>
        </script>
      HTML
    end

    context 'with method argument' do
      let(:file) { <<~HTML }
        <%= javascript_tag(data) %>
      HTML

      it { expect(subject).to(eq(<<~HTML)) }
        <script>
        //<![CDATA[
        <%== data %>
        //]]>
        </script>
      HTML
    end

    context 'without options and block' do
      let(:file) { <<~HTML }
        <%= javascript_tag do %>
          foo
        <% end %>
      HTML

      it { expect(subject).to(eq(<<~HTML)) }
        <script>
        //<![CDATA[

          foo

        //]]>
        </script>
      HTML
    end

    context 'without options and block when correction style is plain' do
      let(:linter_config) { described_class.config_schema.new(correction_style: 'plain') }
      let(:file) { <<~HTML }
        <%= javascript_tag do %>
          foo
        <% end %>
      HTML

      it { expect(subject).to(eq(<<~HTML)) }
        <script>
          foo
        </script>
      HTML
    end

    context 'with html options and block' do
      let(:file) { <<~HTML }
        <%= javascript_tag(defer: true, async: true) do %>
          foo
        <% end %>
      HTML

      it { expect(subject).to(eq(<<~HTML)) }
        <script defer="true" async="true">
        //<![CDATA[

          foo

        //]]>
        </script>
      HTML
    end

    context 'with old hash syntax options and block' do
      let(:file) { <<~HTML }
        <%= javascript_tag('defer' => true, :async => 'true') do %>
          foo
        <% end %>
      HTML

      it { expect(subject).to(eq(<<~HTML)) }
        <script defer="true" async="true">
        //<![CDATA[

          foo

        //]]>
        </script>
      HTML
    end
  end

  private

  def build_offense(range)
    ERBLint::Offense.new(
      linter,
      processed_source.to_source_range(range),
      "Avoid using 'javascript_tag do' as it confuses tests "\
      "that validate html, use inline <script> instead"
    )
  end
end
