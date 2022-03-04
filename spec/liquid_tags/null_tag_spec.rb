require "rails_helper"

RSpec.describe NullTag, type: :liquid_tag do
  describe "#initialize" do
    tags = %w[assign capture case cycle for if ifchanged include unless]

    before { tags.each { |tag| Liquid::Template.register_tag(tag, described_class) } }

    def generate_given_tag(tag)
      Liquid::Template.parse("{% #{tag} %}")
    end

    context "when attempting the tags" do
      it "prevents the tag from being used" do
        tags.each do |tag|
          expect { generate_given_tag(tag) }.to raise_error(StandardError)
        end
      end
    end
  end
end
