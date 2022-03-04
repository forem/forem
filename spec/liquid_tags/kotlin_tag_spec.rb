require "rails_helper"

RSpec.describe KotlinTag, type: :liquid_tag do
  describe "#link" do
    let(:valid_url_id_only) { "https://pl.kotl.in/owreUFFUG" }
    let(:valid_url_one_param) { "https://pl.kotl.in/owreUFFUG?theme=darcula" }
    let(:valid_url_multiple_params) { "https://pl.kotl.in/owreUFFUG?theme=darcula&from=3&to=6&readOnly=true" }
    let(:invalid_url) { "https://example.com" }
    let(:invalid_url_typo) { "https://pl.kotlin.in/owreUFFUG" }

    def generate_new_liquid(link)
      Liquid::Template.register_tag("kotlin", KotlinTag)
      Liquid::Template.parse("{% kotlin #{link} %}")
    end

    context "with valid Kotlin urls" do
      it "generates correct liquid from url without params" do
        liquid = generate_new_liquid(valid_url_id_only)
        expect(liquid.render).to include("<iframe")
        expect(liquid.render).to include("src=\"https://pl.kotl.in/owreUFFUG\"")
      end

      it "generates correct liquid from url with one or more params" do
        liquid1 = generate_new_liquid(valid_url_one_param)
        expect(liquid1.render).to include("<iframe")
        expect(liquid1.render).to include("src=\"https://pl.kotl.in/owreUFFUG?theme=darcula\"")

        liquid2 = generate_new_liquid(valid_url_multiple_params)
        expect(liquid2.render).to include("<iframe")
        expect(liquid2.render).to include("src=\"https://pl.kotl.in/owreUFFUG?theme=darcula&amp;from=3&amp;to=6&amp;readOnly=true\"")
      end
    end

    context "with invalid Kotlin urls" do
      it "returns StandardError from invalid urls" do
        expect do
          generate_new_liquid(invalid_url)
        end.to raise_error(StandardError)

        expect do
          generate_new_liquid(invalid_url_typo)
        end.to raise_error(StandardError)
      end
    end
  end
end
