require "rails_helper"

RSpec.describe GithubTag::GithubIssueTag, type: :liquid_tag, vcr: true do
  describe "#id" do
    let(:url_issue) { "https://github.com/forem/forem/issues/7434" }
    let(:url_issue_with_dot_character) { "https://github.com/thepracticaldev/dev.to/issues/7434" }
    let(:url_issue_fragment) { "https://github.com/forem/forem/issues/7434#issue-604653303" }
    let(:url_pull_request) { "https://github.com/forem/forem/pull/7653" }
    let(:url_pull_request_issue_fragment) { "https://github.com/forem/forem/pull/7653#issue-412271322" }
    let(:url_issue_comment) { "https://github.com/forem/forem/issues/7434#issuecomment-621043602" }
    let(:url_pull_request_comment) { "https://github.com/forem/forem/pull/7653#issuecomment-622572436" }
    let(:url_not_found) { "https://github.com/forem/forem/issues/0" }

    def generate_tag(url)
      Liquid::Template.register_tag("github", GithubTag)
      Liquid::Template.parse("{% github #{url} %}")
    end

    it "rejects GitHub URL without domain" do
      expect do
        generate_tag("/react/issues/9193")
      end.to raise_error(StandardError)
    end

    it "rejects invalid GitHub issue URL" do
      expect do
        generate_tag("https://github.com/issues/9193")
      end.to raise_error(StandardError)
    end

    it "rejects a non existing GitHub issue URL" do
      VCR.use_cassette("github_client_issue_not_found") do
        expect do
          generate_tag(url_not_found)
        end.to raise_error(StandardError)
      end
    end

    it "renders an issue URL" do
      VCR.use_cassette("github_client_issue") do
        html = generate_tag(url_issue).render
        expect(html).to include("#7434")
      end
    end

    it "renders an issue URL with dot character" do
      VCR.use_cassette("github_client_issue_with_dot_character") do
        html = generate_tag(url_issue_with_dot_character).render
        expect(html).to include("#7434")
      end
    end

    it "renders an issue URL with an issue fragment" do
      VCR.use_cassette("github_client_issue") do
        html = generate_tag(url_issue_fragment).render
        expect(html).to include("#7434")
      end
    end

    it "renders a pull request URL" do
      VCR.use_cassette("github_client_pull_request") do
        html = generate_tag(url_pull_request).render
        expect(html).to include("#7653")
      end
    end

    it "renders a pull request URL with an issue fragment" do
      VCR.use_cassette("github_client_pull_request") do
        html = generate_tag(url_pull_request_issue_fragment).render
        expect(html).to include("#7653")
      end
    end

    it "renders an issue comment" do
      VCR.use_cassette("github_client_comment") do
        html = generate_tag(url_issue_comment).render
        expect(html).to include("621043602")
      end
    end

    it "renders a PR comment" do
      VCR.use_cassette("github_client_pull_request_comment") do
        html = generate_tag(url_pull_request_comment).render
        expect(html).to include("622572436")
      end
    end
  end
end
