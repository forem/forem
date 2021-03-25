require "rails_helper"

RSpec.describe CodepenTag, type: :liquid_tag do
  describe "#link" do
    let(:codepen_link) { "https://codepen.io/twhite96/pen/XKqrJX" }
    let(:codepen_team_link) { "https://codepen.io/team/keyframers/pen/ZMRMEw" }
    let(:codepen_link_with_default_tab) { "https://codepen.io/twhite96/pen/XKqrJX default-tab=js,result" }

    xss_links = %w(
      //evil.com/?codepen.io
      https://codepen.io.evil.com
      https://codepen.io/some_username/pen/" onload='alert("xss")'
    )

    def generate_new_liquid(link)
      Liquid::Template.register_tag("codepen", CodepenTag)
      Liquid::Template.parse("{% codepen #{link} %}")
    end

    it "accepts codepen link" do
      liquid = generate_new_liquid(codepen_link)

      expect(liquid.render).to include("<iframe")
        .and include(
          'src="https://codepen.io/twhite96/embed/XKqrJX?height=600&default-tab=result&embed-version=2"',
        )
    end

    it "accepts codepen link with a / at the end" do
      codepen_link = "https://codepen.io/twhite96/pen/XKqrJX/"
      expect do
        generate_new_liquid(codepen_link)
      end.not_to raise_error
    end

    it "accepts codepen team link" do
      codepen_link = codepen_team_link
      expect do
        generate_new_liquid(codepen_link)
      end.not_to raise_error
    end

    it "accepts codepen link with an underscore in the username" do
      codepen_link = "https://codepen.io/t_white96/pen/XKqrJX/"
      expect do
        generate_new_liquid(codepen_link)
      end.not_to raise_error
    end

    it "rejects invalid codepen link" do
      expect do
        generate_new_liquid("invalid_codepen_link")
      end.to raise_error(StandardError)
    end

    it "rejects codepen link with more than 30 characters in the username" do
      codepen_link = "https://codepen.io/t_white96_this_is_31_characters/pen/XKqrJX/"
      expect do
        generate_new_liquid(codepen_link)
      end.to raise_error(StandardError)
    end

    it "accepts codepen link with a default-tab parameter" do
      expect do
        generate_new_liquid(codepen_link_with_default_tab)
      end.not_to raise_error
    end

    it "rejects XSS attempts" do
      xss_links.each do |link|
        expect { generate_new_liquid(link) }.to raise_error(StandardError)
      end
    end

    it "rejects multiline XSS attempt" do
      xss_multiline_link = <<~XSS
        javascript:exploit_code();/*
        #{codepen_link}
        */
      XSS
      expect { generate_new_liquid(xss_multiline_link) }.to raise_error(StandardError)
    end
  end
end
