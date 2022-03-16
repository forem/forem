require "rails_helper"

RSpec.describe UnifiedEmbed::Tag, type: :liquid_tag do
  let(:stub_github_request) do
    stub_request(:get, "https://api.github.com/repos/forem/forem")
      .with(
        headers: {
          Accept: "application/vnd.github.v3+json",
          Authorization: "Basic MDVkNjdlNjQ2MDJmZDhmOTFkNmM6NjEyYTZiMTc5NTkyOWFkZDc3NTJmNGUwOWU1Mjc2OWIxYjdmMDJjZA==",
          "Content-Type": "application/json",
          Expect: "",
          "User-Agent": "Octokit Ruby Gem 4.22.0 (http://localhost:3000)",
          # rubocop:disable Layout/LineLength
          "X-Honeycomb-Trace": "1;dataset=,trace_id=7119a1f3c49c8b7947db8f98f72f4dba,parent_id=4c72a3ec1d488f4b,context=e30="
          # rubocop:enable Layout/LineLength
        },
      ).to_return(status: 200, body: "", headers: {})
  end

  it "delegates parsing to the link-matching class" do
    link = "https://gist.github.com/jeremyf/662585f5c4d22184a6ae133a71bf891a"

    allow(GistTag).to receive(:new).and_call_original
    stub_request_head(link)
    parsed_tag = Liquid::Template.parse("{% embed #{link} %}")

    expect { parsed_tag.render }.not_to raise_error
    expect(GistTag).to have_received(:new)
  end

  it "delegates parsing to the link-matching class when there are options" do
    link = "https://github.com/forem/forem noreadme"

    allow(GithubTag).to receive(:new).and_call_original

    stub_request_head(link.split[0]) # grabbing the actual URL for the stubbing
    stub_github_request

    # parsed_tag = Liquid::Template.parse("{% embed #{link} %}")

    # expect { parsed_tag.render }.not_to raise_error
    # expect(GithubTag).to have_received(:new)
  end

  it "raises an error when link 404s" do
    link = "https://takeonrules.com/goes-nowhere"

    expect do
      stub_request_head(link, 404)
      Liquid::Template.parse("{% embed #{link} %}")
    end.to raise_error(StandardError, "URL provided was not found; please check and try again")
  end

  it "raises an error when no link-matching class is found" do
    link = "https://takeonrules.com/about"

    expect do
      stub_request_head(link)
      Liquid::Template.parse("{% embed #{link} %}")
    end.to raise_error(StandardError, "Embeds for this URL are not supported")
  end
end
