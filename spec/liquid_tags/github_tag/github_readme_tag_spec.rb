require "rails_helper"

RSpec.describe GithubTag::GithubReadmeTag, type: :liquid_tag, vcr: true do
  describe "#id" do
    let(:url_repository) { "https://github.com/rust-lang/rust" }
    let(:url_repository_fragment) { "https://github.com/rust-lang/rust#contributing" }
    let(:url_repository_not_found) { "https://github.com/abra/cadabra" }
    let(:url_repository_relative_links) { "https://github.com/nlepage/gophers" }
    let(:path_repository) { "rust-lang/rust" }
    let(:repo_owner) { "rust-lang" }
    let(:relative_link) { "<a href=\"https://github.com/nlepage/gophers#license\">License</a>" }

    def generate_tag(path, options = "")
      Liquid::Template.register_tag("github", GithubTag)
      Liquid::Template.parse("{% github #{path} #{options} %}")
    end

    it "rejects GitHub URL without domain" do
      expect do
        generate_tag("dsdsdsdsdssd3")
      end.to raise_error(StandardError)
    end

    it "rejects invalid GitHub repository URL" do
      expect do
        generate_tag("https://github.com/repository")
      end.to raise_error(StandardError)
    end

    it "rejects a non existing GitHub repository URL" do
      VCR.use_cassette("github_client_repository_not_found") do
        expect do
          generate_tag(url_repository_not_found)
        end.to raise_error(StandardError)
      end
    end

    it "renders a repository URL" do
      VCR.use_cassette("github_client_repository") do
        html = generate_tag(url_repository).render
        expect(html).to include(repo_owner)
      end
    end

    it "renders a repository path" do
      VCR.use_cassette("github_client_repository") do
        html = generate_tag(path_repository).render
        expect(html).to include(repo_owner)
      end
    end

    it "renders a repository URL with a trailing slash" do
      VCR.use_cassette("github_client_repository") do
        html = generate_tag("#{url_repository}/").render
        expect(html).to include(repo_owner)
      end
    end

    it "renders a repository path with a trailing slash" do
      VCR.use_cassette("github_client_repository") do
        html = generate_tag("#{path_repository}/").render
        expect(html).to include(repo_owner)
      end
    end

    it "renders a repository URL with a fragment" do
      VCR.use_cassette("github_client_repository") do
        html = generate_tag(url_repository_fragment).render
        expect(html).to include(repo_owner)
      end
    end

    it "renders a repository with a missing README" do
      allow_any_instance_of(Github::OauthClient).to receive(:readme).and_raise(Github::Errors::NotFound) # rubocop:disable RSpec/AnyInstance

      VCR.use_cassette("github_client_repository") do
        template = generate_tag(url_repository).render
        readme_class = "ltag-github-body"
        expect(template).not_to include(readme_class)
      end
    end

    it "renders a repository with relative links in README" do
      VCR.use_cassette("github_client_repository_relative_links") do
        html = generate_tag(url_repository_relative_links).render
        expect(html).to include(relative_link)
      end
    end

    describe "options" do
      it "rejects invalid options" do
        expect do
          generate_tag(url_repository, "acme").render
        end.to raise_error(StandardError)
      end

      it "accepts 'no-readme' as an option" do
        VCR.use_cassette("github_client_repository_no_readme") do
          template = generate_tag(url_repository, "no-readme").render
          readme_css_class = "ltag-github-body"
          expect(template).not_to include(readme_css_class)
        end
      end
    end

    describe "regressions" do
      it "parses a repository with invalid img tags" do
        VCR.use_cassette("github_client_repository_invalid_img_tag") do
          # this particular repository contains the tag `<img style="max-width:100%;">`
          # which shouldn't fail rendering
          html = generate_tag("sirixdb/sirix").render
          expect(html).to include("sirix")
        end
      end
    end
  end
end
