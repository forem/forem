require "rails_helper"

RSpec.describe CodesharerTag, type: :liquid_tag do
  describe "#link" do
    let(:valid_link) { "https://codesharer.netlify.app/#XQAAAAJfAQAAAAAAAAA0mYABgLEl9To0sULAdveASTrLFD8ZLSLdyniHR0mKJkIjTzSEHjEcJApXpFz9qcoCe7Vrgg83lUKsQO+zjFGOsHiGsLnBBGpsb9qFeBiow4WEBpd3FgbuEs/Rg/GO3SRMabk459x45fl63FDX5iZzAZvek4ziAZq8BXWToWk/twStnCkwlsr9DR0WVCZfwjgJmU6OT8jNPd/7nzYLgd7WparKYFSqrYIbVyBqZgE3sXGJlndextUrO7R0H1JHJxqE7UKLqzJtaiH/+T4LQA==" }

    def generate_new_liquid(link)
      Liquid::Template.register_tag("codesharer", CodesharerTag)
      Liquid::Template.parse("{% codesharer #{link} %}")
    end

    it "accepts only Code Sharer links" do
      badurl = "https://example.com"
      expect do
        generate_new_liquid(badurl)
      end.to raise_error(StandardError)

      badurl = "not even an URL"
      expect do
        generate_new_liquid(badurl)
      end.to raise_error(StandardError)
    end

    def check(url, expected)
      expect(described_class.parse_link(url)).to eq(expected)
    end

    it "produces a correct final URL" do
      expected = "https://codesharer.netlify.app/#XQAAAAJfAQAAAAAAAAA0mYABgLEl9To0sULAdveASTrLFD8ZLSLdyniHR0mKJkIjTzSEHjEcJApXpFz9qcoCe7Vrgg83lUKsQO+zjFGOsHiGsLnBBGpsb9qFeBiow4WEBpd3FgbuEs/Rg/GO3SRMabk459x45fl63FDX5iZzAZvek4ziAZq8BXWToWk/twStnCkwlsr9DR0WVCZfwjgJmU6OT8jNPd/7nzYLgd7WparKYFSqrYIbVyBqZgE3sXGJlndextUrO7R0H1JHJxqE7UKLqzJtaiH/+T4LQA=="
      expect(described_class.embedded_url(valid_link)).to eq(expected)
    end

    it "renders correctly a Code Sharer link" do
      liquid = generate_new_liquid(valid_link)
      rendered_codesharer_iframe = liquid.render
      Approvals.verify(rendered_codesharer_iframe, name: "codesharer_liquid_tag", format: :html)
    end
  end
end
