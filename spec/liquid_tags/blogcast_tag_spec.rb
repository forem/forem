require "rails_helper"

RSpec.describe BlogcastTag, type: :liquid_template do
  describe "#id" do
    let(:valid_id)      { "1234" }
    let(:invalid_id)    { "inv@lid" }

    def generate_tag(id)
      Liquid::Template.register_tag("blogcast", BlogcastTag)
      Liquid::Template.parse("{% blogcast #{id} %}")
    end

    it "rejects invalid ids" do
      expect { generate_tag(invalid_id) }.to raise_error(StandardError)
    end

    it "accepts a valid id" do
      expect { generate_tag(valid_id) }.not_to raise_error
    end
  end
end
