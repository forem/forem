require "rails_helper"

RSpec.describe StatickitTag, type: :liquid_template do
  describe "#id" do
    let(:statickit_id) { "8h34hp284732" }

    def generate_new_liquid(id)
      Liquid::Template.register_tag("statickit", StatickitTag)
      Liquid::Template.parse("{% statickit #{id} %}")
    end

    it "accepts statickit id" do
      expect { generate_new_liquid(statickit_id) }.not_to raise_error
    end
  end
end
