require "rails_helper"

RSpec.describe UserTag, type: :liquid_template do
  let(:user)  { create(:user) }

  setup       { Liquid::Template.register_tag("user", described_class) }

  def generate_user_tag(id_code)
    Liquid::Template.parse("{% user #{id_code} %}")
  end

  context "when given valid id_code" do
    it "renders the proper user name" do
      liquid = generate_user_tag(user.username)
      expect(liquid.render).to include(user.name)
    end

    it "renders image html" do
      liquid = generate_user_tag(user.username)
      expect(liquid.render).to include("<img")
    end
  end

  it "rejects invalid id_code" do
    expect do
      generate_user_tag("this should fail")
    end.to raise_error(StandardError)
  end
end
