require "rails_helper"

RSpec.describe FastlyConfig::Snippets, type: :service do
  let(:fastly) { instance_double Fastly }
  let(:fastly_version) { instance_double Fastly::Version }
  let(:fastly_snippet) { instance_double Fastly::Snippet }
  let(:fastly_dictionary) { instance_double Fastly::Dictionary }
  let(:snippets_config) { described_class.new(fastly, fastly_version) }

  before do
    allow(fastly).to receive(:get_dictionary).and_return(fastly_dictionary)
  end

  it "determines if an update is needed" do
    allow(fastly_version).to receive(:number).and_return(1)
    allow(fastly).to receive(:get_snippet).and_return(fastly_snippet)
    allow(fastly_snippet).to receive(:content).and_return("some VCL")
    expect(snippets_config.update_needed?).to be true
  end

  describe "upsert_config" do
    it "creates a new snippet if one isn't found" do
      allow(fastly_version).to receive(:number).and_return(1)
      allow(fastly).to receive_messages(get_snippet: nil, create: fastly_snippet)
      allow(fastly_snippet).to receive(:name).and_return("test")
      snippets_config.update(fastly_version)
      expect(fastly).to have_received(:create).at_least(:once)
    end

    it "updates a snippet if one is found" do
      allow(fastly_version).to receive(:number).and_return(1)
      allow(fastly).to receive(:get_snippet).and_return(fastly_snippet)
      allow(fastly_snippet).to receive_messages(content: "test", "content=": "test", save!: fastly_snippet,
                                                name: "test")
      snippets_config.update(fastly_version)
      expect(fastly_snippet).to have_received(:save!).at_least(:once)
    end

    it "preserves table.lookup when the referenced Fastly dictionary exists" do
      allow(fastly_version).to receive(:number).and_return(1)
      allow(fastly).to receive_messages(get_snippet: nil, create: fastly_snippet)
      allow(fastly_snippet).to receive(:name).and_return("test")

      snippets_config.update(fastly_version)

      expect(fastly).to have_received(:create).with(
        Fastly::Snippet,
        hash_including(
          name: "Check for remember user token in cookie to set header",
          content: include('table.lookup(forem_edge, "cloudflare_secret", "")'),
        ),
      )
    end

    it "replaces table.lookup with its default value when the referenced Fastly dictionary does not exist" do
      allow(fastly_version).to receive(:number).and_return(1)
      allow(fastly).to receive(:get_dictionary).and_raise(Fastly::Error.new('{"msg":"Record not found"}'))
      allow(fastly).to receive_messages(get_snippet: nil, create: fastly_snippet)
      allow(fastly_snippet).to receive(:name).and_return("test")

      snippets_config.update(fastly_version)

      expect(fastly).to have_received(:create).with(
        Fastly::Snippet,
        hash_including(
          name: "Check for remember user token in cookie to set header",
          content: satisfy do |vcl|
            vcl.include?('digest.secure_is_equal(req.http.X-Forem-Edge-Secret, "")') &&
              vcl.exclude?("table.lookup(forem_edge")
          end,
        ),
      )
    end

    it "logs success messages" do
      allow(ForemStatsClient).to receive(:increment)
      allow(fastly_version).to receive(:number).and_return(1)
      allow(fastly).to receive(:get_snippet).and_return(fastly_snippet)
      allow(fastly_snippet).to receive_messages(content: "test", "content=": "test", save!: fastly_snippet,
                                                name: "test")

      snippets_config.update(fastly_version)

      tags = hash_including(tags: array_including("snippet_update_type:update", "snippet_name:test",
                                                  "new_version:#{fastly_version.number}"))

      expect(ForemStatsClient).to have_received(:increment).with("fastly.snippets", tags).at_least(:once)
    end
  end
end
