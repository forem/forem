require "rails_helper"

RSpec.describe Settings::AiFunctions do
  it "defaults to no selections" do
    expect(described_class.global_function_models).to eq({})
  end

  it "stores selections globally, regardless of the request's subforem" do
    subforem = create(:subforem)
    RequestStore.store[:subforem_id] = subforem.id

    described_class.set_global_function_models("article_spam_check" => "jev")

    expect(described_class.find_by(var: "function_models").subforem_id).to be_nil
    RequestStore.store[:subforem_id] = nil
    expect(described_class.function_model(:article_spam_check)).to eq("jev")
  end

  describe "spam escalation threshold" do
    it "defaults to 0.3" do
      expect(described_class.global_spam_escalation_threshold).to eq(0.3)
    end

    it "is stored globally, regardless of the request's subforem" do
      RequestStore.store[:subforem_id] = create(:subforem).id
      described_class.set_global_spam_escalation_threshold("0.45")
      RequestStore.store[:subforem_id] = nil

      expect(described_class.global_spam_escalation_threshold).to eq(0.45)
    end

    it "rejects values outside (0, 1]" do
      expect { described_class.set_global_spam_escalation_threshold("0") }
        .to raise_error(ActiveRecord::RecordInvalid)
      expect { described_class.set_global_spam_escalation_threshold("1.5") }
        .to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  it "replaces previous selections" do
    described_class.set_global_function_models("article_spam_check" => "jev")
    described_class.set_global_function_models("comment_spam_check" => "jev")

    expect(described_class.global_function_models).to eq("comment_spam_check" => "jev")
  end
end
