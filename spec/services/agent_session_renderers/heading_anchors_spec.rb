require "rails_helper"

RSpec.describe AgentSessionRenderers::HeadingAnchors do
  subject(:anchors) { described_class.new("agent-session-7-3") }

  describe ".slugify" do
    it "slugs headings the way GitHub does" do
      expect(described_class.slugify("Getting Started")).to eq("getting-started")
      expect(described_class.slugify("FAQ &amp; Troubleshooting")).to eq("faq--troubleshooting")
      expect(described_class.slugify("What&#39;s New in v2.0?")).to eq("whats-new-in-v20")
      expect(described_class.slugify("Astro vs WordPress: the practical comparison"))
        .to eq("astro-vs-wordpress-the-practical-comparison")
    end

    it "keeps hyphens and underscores" do
      expect(described_class.slugify("Work through a small-business example_now"))
        .to eq("work-through-a-small-business-example_now")
    end

    it "uses the text of inline markup" do
      expect(described_class.slugify("Call <code>run()</code> <em>now</em>")).to eq("call-run-now")
    end

    it "keeps non-latin letters" do
      expect(described_class.slugify("Überblick über Café")).to eq("überblick-über-café")
    end
  end

  describe "#register" do
    it "prefixes the slug with the scope" do
      expect(anchors.register("Introduction")).to eq("agent-session-7-3-introduction")
    end

    it "deduplicates repeated headings with GitHub-style suffixes" do
      expect(anchors.register("Usage")).to eq("agent-session-7-3-usage")
      expect(anchors.register("Usage")).to eq("agent-session-7-3-usage-1")
      expect(anchors.register("Usage")).to eq("agent-session-7-3-usage-2")
    end

    it "returns nil for a heading without sluggable text" do
      expect(anchors.register("!!! ???")).to be_nil
    end
  end

  describe "#link_fragments" do
    before do
      anchors.register("Getting Started")
      anchors.register("FAQ &amp; Troubleshooting")
    end

    it "points links at the scoped heading ids" do
      html = '<a href="#getting-started">Go</a> <a href="#faq--troubleshooting">FAQ</a>'
      expect(anchors.link_fragments(html)).to eq(
        '<a href="#agent-session-7-3-getting-started">Go</a> ' \
        '<a href="#agent-session-7-3-faq--troubleshooting">FAQ</a>',
      )
    end

    it "matches percent-encoded and differently cased fragments" do
      anchors.register("Überblick")
      expect(anchors.link_fragments('<a href="#%C3%BCberblick">x</a>'))
        .to eq('<a href="#agent-session-7-3-überblick">x</a>')
      expect(anchors.link_fragments('<a href="#Getting-Started">x</a>'))
        .to eq('<a href="#agent-session-7-3-getting-started">x</a>')
    end

    it "leaves links without a matching heading and non-fragment links alone" do
      html = '<a href="#missing">x</a> <a href="https://example.com/#getting-started">y</a>'
      expect(anchors.link_fragments(html)).to eq(html)
    end
  end
end
