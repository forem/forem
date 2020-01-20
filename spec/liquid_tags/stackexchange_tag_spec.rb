require "rails_helper"

RSpec.describe StackexchangeTag, type: :liquid_tag, vcr: true do
  describe "#id" do
    let(:valid_id) { "57496168" }
    let(:exchange_id) { "1163633" }
    let(:invalid_id) { "57496168sddssd" }
    let(:valid_id_deleted_question) { "59679915" }

    def generate_new_liquid(id)
      Liquid::Template.register_tag("stackoverflow", StackexchangeTag)
      Liquid::Template.parse("{% stackoverflow #{id} %}")
    end

    def generate_exchange_liquid(id)
      Liquid::Template.register_tag("stackexchange", StackexchangeTag)
      Liquid::Template.parse("{% stackexchange #{id} askubuntu %}")
    end

    it "renders basic stackoverflow html" do
      VCR.use_cassette("stackexchange_tag_stackoverflow") do
        liquid = generate_new_liquid(valid_id)
        expect(liquid.render).to include("ltag__stackexchange")
        expected_answer_url = "https://stackoverflow.com/questions/57496168/use-where-and-limit-to-child-in-foreach"
        expect(liquid.render).to include("<a href=\"#{expected_answer_url}\"")
      end
    end

    it "renders basic stackexchange html" do
      VCR.use_cassette("stackexchange_tag_stackexchange") do
        liquid = generate_exchange_liquid(exchange_id)
        expect(liquid.render).to include("stackexchange-logo")
        expected_answer_url = "https://askubuntu.com/questions/885432/help-setting-up-sshfs/1163633#1163633"
        expect(liquid.render).to include("<a href=\"#{expected_answer_url}\"")
      end
    end

    it "rejects invalid id" do
      expect do
        liquid = generate_exchange_liquid(invalid_id)
        liquid.render
      end.to raise_error(StandardError)
    end

    it "does not break with volountarily removed questions" do
      VCR.use_cassette("stackexchange_tag_deleted_question") do
        expect do
          liquid = generate_exchange_liquid(valid_id_deleted_question)
          liquid.render
        end.to raise_error(StandardError, /find a post with that ID/)
      end
    end
  end
end
