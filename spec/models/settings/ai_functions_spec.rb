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

  it "replaces previous selections" do
    described_class.set_global_function_models("article_spam_check" => "jev")
    described_class.set_global_function_models("comment_spam_check" => "jev")

    expect(described_class.global_function_models).to eq("comment_spam_check" => "jev")
  end
end
