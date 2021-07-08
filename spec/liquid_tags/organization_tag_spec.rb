require "rails_helper"

RSpec.describe OrganizationTag, type: :liquid_tag do
  let(:organization) { create(:organization) }

  before { Liquid::Template.register_tag("organization", described_class) }

  def generate_user_tag(id_code)
    Liquid::Template.parse("{% organization #{id_code} %}")
  end

  context "when given valid id_code" do
    it "renders the proper user name" do
      liquid = generate_user_tag(organization.slug)
      expect(liquid.render).to include(organization.slug)
    end

    it "renders image html" do
      liquid = generate_user_tag(organization.slug)
      expect(liquid.render).to include("<img")
    end
  end

  it "rejects invalid id_code" do
    expect do
      generate_user_tag("this should fail")
    end.to raise_error(StandardError)
  end
end
