# RFC 8058: bulk mail must expose a List-Unsubscribe URL plus the
# List-Unsubscribe-Post opt-in so Gmail/Yahoo can render a native
# one-click unsubscribe control.
RSpec.shared_examples "#renders_one_click_unsubscribe_headers" do
  it "renders the one-click unsubscribe headers", :aggregate_failures do
    list_unsubscribe = email["List-Unsubscribe"].value

    expect(list_unsubscribe).to start_with("<")
    expect(list_unsubscribe).to end_with(">")
    expect(list_unsubscribe).to include("/email_subscriptions/unsubscribe?ut=")
    expect(email["List-Unsubscribe-Post"].value).to eq("List-Unsubscribe=One-Click")
  end
end
