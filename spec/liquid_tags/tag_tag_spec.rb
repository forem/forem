require "rails_helper"

RSpec.describe TagTag, type: :liquid_tag do
  let(:tag) { create(:tag) }

  before { Liquid::Template.register_tag("tag", described_class) }

  def generate_tag_tag(id_code)
    Liquid::Template.parse("{% tag #{id_code} %}")
  end

  context "when given valid id_code" do
    it "renders the proper tag name" do
      liquid = generate_tag_tag(tag.name)
      expect(liquid.render).to include(tag.name)
    end

    it "renders tag short summary" do
      liquid = generate_tag_tag(tag.name)
      expect(liquid.render).to include(tag.short_summary.to_s)
    end
  end

  it "rejects invalid id_code" do
    expect do
      generate_tag_tag("this should fail")
    end.to raise_error(StandardError)
  end
end
