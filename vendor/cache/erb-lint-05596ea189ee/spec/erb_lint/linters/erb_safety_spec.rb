# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Linters::ErbSafety do
  let(:linter_config) { described_class.config_schema.new }
  let(:better_html_config) do
    {
      javascript_safe_methods: %w(to_json),
    }
  end
  let(:file_loader) { MockFileLoader.new(better_html_config) }
  let(:linter) { described_class.new(file_loader, linter_config) }
  let(:processed_source) { ERBLint::ProcessedSource.new('file.rb', file) }
  subject { linter.offenses }
  before { linter.run(processed_source) }

  class MockFileLoader
    def initialize(config)
      @config = config
    end

    def yaml(_filename)
      @config
    end
  end

  context 'interpolate a variable in js attribute' do
    let(:file) { <<~FILE }
      <a onclick="alert('<%= foo %>')">
    FILE

    it { expect(subject).to(eq([unsafe_interpolate(23..25)])) }
  end

  context 'interpolate a variable in js attribute calling safe method' do
    let(:file) { <<~FILE }
      <a onclick="alert(<%= foo.to_json %>)">
    FILE

    it { expect(subject).to(eq([])) }
  end

  context 'interpolate a variable in js attribute calling safe method inside string interpolation' do
    let(:file) { <<~FILE }
      <a onclick="alert(<%= "hello \#{foo.to_json}" %>)">
    FILE

    it { expect(subject).to(eq([])) }
  end

  context 'html_safe in any attribute is unsafe' do
    let(:file) { <<~FILE }
      <div title="<%= foo.html_safe %>">
    FILE

    it { expect(subject).to(eq([unsafe_html_safe(16..28)])) }
  end

  context 'html_safe in any attribute is unsafe despite having to_json' do
    let(:file) { <<~FILE }
      <a onclick="<%= foo.to_json.html_safe %>">
    FILE

    it { expect(subject).to(eq([unsafe_html_safe(16..36), unsafe_interpolate(16..36)])) }
  end

  context '<== in any attribute is unsafe' do
    let(:file) { <<~FILE }
      <div title="<%== foo %>">
    FILE

    it { expect(subject).to(eq([unsafe_erb_interpolate(12..22)])) }
  end

  context '<== in any attribute is unsafe despite having to_json' do
    let(:file) { <<~FILE }
      <div title="<%== foo.to_json %>">
    FILE

    it { expect(subject).to(eq([unsafe_erb_interpolate(12..30)])) }
  end

  context 'raw in any attribute is unsafe' do
    let(:file) { <<~FILE }
      <div title="<%= raw foo %>">
    FILE

    it { expect(subject).to(eq([unsafe_raw(16..22)])) }
  end

  context 'raw in any attribute is unsafe despite having to_json' do
    let(:file) { <<~FILE }
      <div title="<%= raw foo.to_json %>">
    FILE

    it { expect(subject).to(eq([unsafe_raw(16..30)])) }
  end

  context 'unsafe erb in <script>' do
    let(:file) { <<~FILE }
      <script>var foo = <%= unsafe %>;</script>
    FILE

    it { expect(subject).to(eq([unsafe_javascript_tag_interpolate(18..30)])) }
  end

  context 'safe erb in <script>' do
    let(:file) { <<~FILE }
      <script>var foo = <%= unsafe.to_json %>;</script>
    FILE

    it { expect(subject).to(eq([])) }
  end

  context 'safe erb in <script> when raw is present' do
    let(:file) { <<~FILE }
      <script>var foo = <%= raw unsafe.to_json %>;</script>
    FILE

    it { expect(subject).to(eq([])) }
  end

  context 'statements not allowed in <script> tags' do
    let(:file) { <<~FILE }
      <script><% if foo? %>var foo = 1;<% end %></script>
    FILE

    it { expect(subject).to(eq([erb_statements_not_allowed(8..20)])) }
  end

  context 'changing better-html config file works' do
    let(:linter_config) do
      described_class.config_schema.new(
        'better_html_config' => '.better-html.yml'
      )
    end
    let(:file) { <<~FILE }
      <script><%= foobar %></script>
    FILE

    context 'with default config' do
      let(:better_html_config) { {} }
      it { expect(subject).to(eq([unsafe_javascript_tag_interpolate(8..20)])) }
    end

    context 'with non-default config' do
      let(:better_html_config) { { javascript_safe_methods: %w(foobar) } }
      it { expect(subject).to(eq([])) }
    end

    context 'with string keys in config' do
      let(:better_html_config) { { 'javascript_safe_methods' => %w(foobar) } }
      it { expect(subject).to(eq([])) }
    end
  end

  private

  def unsafe_interpolate(range)
    build_offense(range,
      "erb interpolation in javascript attribute must be wrapped in safe helper such as '(...).to_json'")
  end

  def unsafe_html_safe(range)
    build_offense(range, "erb interpolation with '<%= (...).html_safe %>' in this context is never safe")
  end

  def unsafe_erb_interpolate(range)
    build_offense(range, "erb interpolation with '<%==' inside html attribute is never safe")
  end

  def unsafe_raw(range)
    build_offense(range, "erb interpolation with '<%= raw(...) %>' in this context is never safe")
  end

  def unsafe_javascript_tag_interpolate(range)
    build_offense(range, "erb interpolation in javascript tag must call '(...).to_json'")
  end

  def erb_statements_not_allowed(range)
    build_offense(range, "erb statement not allowed here; did you mean '<%=' ?")
  end

  def build_offense(range, message)
    ERBLint::Offense.new(linter, processed_source.to_source_range(range), message)
  end
end
