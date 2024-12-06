# frozen_string_literal: true

require "spec_helper"

describe Feedjira::Preprocessor do
  it "returns the xml as parsed by Nokogiri" do
    xml = "<xml></xml>"
    doc = Nokogiri::XML(xml).remove_namespaces!
    processor = described_class.new xml
    escaped = processor.to_xml

    expect(escaped).to eq doc.to_xml
  end

  it "escapes markup in xhtml content" do
    processor = described_class.new sample_atom_xhtml_feed
    escaped = processor.to_xml
    escaped_parts = escaped.split "\n"

    expect(escaped_parts[10]).to match(%r{&lt;i&gt;dogs&lt;/i&gt;}) # title
    expect(escaped_parts[16]).to match(%r{&lt;b&gt;XHTML&lt;/b&gt;}) # summary
    expect(escaped_parts[26]).to match(/&lt;p&gt;$/) # content
  end

  it "leaves escaped html within pre tag" do
    processor = described_class.new(sample_atom_xhtml_with_escpaed_html_in_pre_tag_feed)
    escaped = processor.to_xml
    expected_pre_tag = "        &lt;pre&gt;&amp;lt;b&amp;gt;test&amp;lt;b&amp;gt;&lt;/pre&gt;"
    expect(escaped.split("\n")[7]).to eq(expected_pre_tag)
  end
end
