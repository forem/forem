require "rails_helper"

RSpec.describe SpeakerdeckTag, type: :liquid_tag do
  describe "#id" do
    let(:valid_id)      { "7e9f8c0fa0c949bd8025457181913fd0" }
    let(:invalid_id)    { "blahblahblahbl sdsdssd // dsdssd" }

    def generate_tag(id)
      Liquid::Template.register_tag("speakerdeck", SpeakerdeckTag)
      Liquid::Template.parse("{% speakerdeck #{id} %}")
    end

    it "rejects invalid ids" do
      expect { generate_tag(invalid_id) }.to raise_error(StandardError)
    end

    it "accepts a valid id" do
      expect { generate_tag(valid_id) }.not_to raise_error
    end
  end
end
