require "rails_helper"

RSpec.describe CodepenTag, type: :liquid_tag do
  describe "#link" do
    let(:codepen_private_link) { "https://codepen.io/quezo/pen/e10ca45c611b9cf3c98a1011dedc1471" }
    let(:codepen_link) { "https://codepen.io/twhite96/pen/XKqrJX" }
    let(:codepen_team_private_link) { "https://codepen.io/team/codepen/pen/fb02c34281cb08966ec44b4e1ae22bc3" }
    let(:codepen_team_link) { "https://codepen.io/team/keyframers/pen/ZMRMEw" }
    let(:codepen_link_with_default_tab) { "https://codepen.io/twhite96/pen/XKqrJX default-tab=js,result" }
    let(:codepen_link_with_theme_id) { "https://codepen.io/propjockey/pen/dyVMgBg theme-id=40148" }
    let(:codepen_link_with_preview_indicator) { "https://codepen.io/propjockey/pen/preview/dyVMgBg" }
    let(:codepen_link_with_embed_path) { "https://codepen.io/propjockey/embed/dyVMgBg" }
    let(:codepen_link_with_embed_preview_path) { "https://codepen.io/propjockey/embed/preview/dyVMgBg" }
    let(:codepen_link_with_height_param) { "https://codepen.io/propjockey/pen/dyVMgBg height=300" }
    let(:codepen_link_with_editable_true) { "https://codepen.io/propjockey/pen/dyVMgBg editable=true" }
    let(:codepen_link_with_multiple_params) do
      "https://codepen.io/propjockey/pen/dyVMgBg theme-id=40148 default-tab=js,result height=250 editable=true"
    end
    let(:codepen_link_with_preview_and_params) do
      "https://codepen.io/propjockey/pen/preview/dyVMgBg theme-id=40148 default-tab=js,result"
    end
    let(:codepen_link_with_embed_path_and_params) do
      "https://codepen.io/propjockey/embed/dyVMgBg theme-id=40148 default-tab=js,result"
    end

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

    it "accepts codepen private link" do
      liquid = generate_new_liquid(codepen_private_link)

      expect(liquid.render).to include("<iframe")
        .and include(
          'src="https://codepen.io/quezo/embed/e10ca45c611b9cf3c98a1011dedc1471?height=600&default-tab=result&embed-version=2"',
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

    it "accepts codepen team private link" do
      codepen_link = codepen_team_private_link
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

    it "accepts codepen link with a theme-id parameter" do
      expect do
        generate_new_liquid(codepen_link_with_theme_id)
      end.not_to raise_error

      liquid = generate_new_liquid(codepen_link_with_theme_id)

      expect(liquid.render).to include("<iframe")
        .and include('src="https://codepen.io/propjockey/embed/dyVMgBg?height=600&theme-id=40148')
    end

    it "accepts codepen link with pen/preview in the url" do
      expect do
        generate_new_liquid(codepen_link_with_preview_indicator)
      end.not_to raise_error

      liquid = generate_new_liquid(codepen_link_with_preview_indicator)

      expect(liquid.render).to include("<iframe")
        .and include('src="https://codepen.io/propjockey/embed/preview/dyVMgBg')
    end

    it "accepts codepen link with embed path in the url" do
      expect do
        generate_new_liquid(codepen_link_with_embed_path)
      end.not_to raise_error

      liquid = generate_new_liquid(codepen_link_with_embed_path)

      expect(liquid.render).to include("<iframe")
        .and include('src="https://codepen.io/propjockey/embed/dyVMgBg')
    end

    it "accepts codepen link with embed/preview in the url" do
      expect do
        generate_new_liquid(codepen_link_with_embed_preview_path)
      end.not_to raise_error

      liquid = generate_new_liquid(codepen_link_with_embed_preview_path)

      expect(liquid.render).to include("<iframe")
        .and include('src="https://codepen.io/propjockey/embed/preview/dyVMgBg')
    end

    it "accepts codepen link with a height parameter" do
      expect do
        generate_new_liquid(codepen_link_with_height_param)
      end.not_to raise_error

      liquid = generate_new_liquid(codepen_link_with_height_param)

      expect(liquid.render).to include("<iframe")
        .and include('height="300"')
        .and include('src="https://codepen.io/propjockey/embed/dyVMgBg?height=300')
    end

    it "accepts codepen link with a editable=true parameter" do
      expect do
        generate_new_liquid(codepen_link_with_editable_true)
      end.not_to raise_error

      liquid = generate_new_liquid(codepen_link_with_editable_true)

      expect(liquid.render).to include("<iframe")
        .and include('src="https://codepen.io/propjockey/embed/dyVMgBg?height=600&editable=true')
    end

    it "accepts codepen link with multiple params" do
      expect do
        generate_new_liquid(codepen_link_with_multiple_params)
      end.not_to raise_error

      liquid = generate_new_liquid(codepen_link_with_multiple_params)

      expect(liquid.render).to include("<iframe")
        .and include('height="250"')
        .and include(
          'src="https://codepen.io/propjockey/embed/dyVMgBg?height=250&theme-id=40148&amp;default-tab=js,result&amp;editable=true',
        )
    end

    it "accepts codepen link with preview and params" do
      expect do
        generate_new_liquid(codepen_link_with_preview_and_params)
      end.not_to raise_error

      liquid = generate_new_liquid(codepen_link_with_preview_and_params)

      expect(liquid.render).to include("<iframe")
        .and include(
          'src="https://codepen.io/propjockey/embed/preview/dyVMgBg?height=600&theme-id=40148&amp;default-tab=js,result',
        )
    end

    it "accepts codepen link with embed and params" do
      expect do
        generate_new_liquid(codepen_link_with_embed_path_and_params)
      end.not_to raise_error

      liquid = generate_new_liquid(codepen_link_with_embed_path_and_params)

      expect(liquid.render).to include("<iframe")
        .and include(
          'src="https://codepen.io/propjockey/embed/dyVMgBg?height=600&theme-id=40148&amp;default-tab=js,result',
        )
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
