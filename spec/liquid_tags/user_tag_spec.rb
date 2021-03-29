require "rails_helper"

RSpec.describe UserTag, type: :liquid_tag do
  let(:user)  { create(:user) }

  setup       { Liquid::Template.register_tag("user", described_class) }

  def generate_user_tag(id_code)
    Liquid::Template.parse("{% user #{id_code} %}")
  end

  context "when given valid id_code" do
    it "renders the proper user name" do
      liquid = generate_user_tag(user.username)
      expect(liquid.render).to include(CGI.escapeHTML(user.name))
    end

    it "renders image html" do
      liquid = generate_user_tag(user.username)
      expect(liquid.render).to include("<img")
    end
  end

  context "when given an invalid username" do
    it "renders a missing username and name", aggregate_failures: true do
      liquid = generate_user_tag("nonexistent user")
      expect(liquid.render).to include("[deleted user]")
        .and include("[Deleted User]")
    end
  end
end
