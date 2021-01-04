require "rails_helper"

RSpec.describe Html::RemoveNestedLinebreakInList, type: :service do
  describe "#call" do
    context "when the html argument is nil" do
      it "doesn't raise an error" do
        expect { described_class.call(nil) }.not_to raise_error
      end
    end

    context "when a valid html argument is provided" do
      it "removes nested line breaks in a list" do
        html = "- [A](#a)\n  - [B](#b)\n- [C](#c)"
        parsed_html = described_class.call(html)
        expect(parsed_html).not_to include("<br>")
      end
    end
  end
end
