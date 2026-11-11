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
          content: satisfy do |vcl|
            vcl.include?('table.lookup(forem_edge, "cloudflare_secret", "")') &&
              vcl.include?('table.lookup(custom_domain_orgs, "app_domain", "dev.to")') &&
              vcl.include?('table.lookup(custom_domain_orgs, var.cd_dict_key, "")') &&
              vcl.include?('req.url.path == "/__forem_cd_auth_check"') &&
              vcl.include?(
                'add resp.http.Set-Cookie = "cd_anon=1; Path=/; Max-Age=300; HttpOnly; Secure; SameSite=Lax";',
              )
          end,
        ),
      )
      expect(fastly).to have_received(:create).with(
        Fastly::Snippet,
        hash_including(
          name: "Client geolocation",
          content: include(
            "table.lookup(\n      active_geofencing_regions,\n      var.cacheable_code,\n      \"\"\n    )",
          ),
        ),
      )
      expect(fastly).to have_received(:create).with(
        Fastly::Snippet,
        hash_including(
          name: "Safe params list",
          content: satisfy do |vcl|
            vcl.include?('req.url !~ "^/__forem_cd_auth_check(\?|$)"') &&
              vcl.include?("passed_domain|cd_anon)$")
          end,
        ),
      )
      expect(fastly).to have_received(:create).with(
        Fastly::Snippet,
        hash_including(
          name: "Stale while revalidate controls",
          content: satisfy do |vcl|
            vcl.include?('set beresp.http.Surrogate-Control = "max-age=30";') &&
              vcl.include?("beresp.status != 429") &&
              vcl.include?("(private|no-store)")
          end,
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
              vcl.include?('set var.cd_app_domain = std.tolower("dev.to");') &&
              vcl.include?('set var.cd_slug = "";') &&
              vcl.exclude?("table.lookup(forem_edge") &&
              vcl.exclude?("table.lookup(custom_domain_orgs")
          end,
        ),
      )
      expect(fastly).to have_received(:create).with(
        Fastly::Snippet,
        hash_including(
          name: "Client geolocation",
          content: include("active_geofencing_regions"),
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
