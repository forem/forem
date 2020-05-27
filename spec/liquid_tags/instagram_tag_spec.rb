require "rails_helper"

RSpec.describe InstagramTag, type: :liquid_tag do
  describe "#id" do
    let(:valid_id)      { "BXgGcAUjM39" }
    let(:invalid_id)    { "blahblahblahbl" }

    def generate_instagram_tag(id)
      Liquid::Template.register_tag("instagram", InstagramTag)
      Liquid::Template.parse("{% instagram #{id} %}")
    end

    xit "checks that the tag is properly parsed" do
      valid_id = "BXgGcAUjM39"
      liquid = generate_instagram_tag(valid_id)
      rendered_instagram = liquid.render
      Approvals.verify(rendered_instagram, name: "instagram_liquid_tag", format: :html)
    end

    xit "rejects invalid ids" do
      expect { generate_instagram_tag(invalid_id) }.to raise_error(StandardError)
    end

    xit "accepts a valid id" do
      expect { generate_instagram_tag(valid_id) }.not_to raise_error
    end
  end
end
