
require "spec_helper"

describe JsRoutes, "compatibility with Rails"  do

  before(:each) do
    evallib(module_type: nil, namespace: 'Routes')
  end

  context "when specs" do
    it "should show inbox spec" do
      expectjs("Routes.inbox_path.toString()").to eq('/inboxes/:id(.:format)')
    end

    it "should show inbox spec convert to string" do
      expectjs("'' + Routes.inbox_path").to eq('/inboxes/:id(.:format)')
    end

    it "should show inbox message spec" do
      expectjs("Routes.inbox_message_path.toString()").to eq('/inboxes/:inbox_id/messages/:id(.:format)')
    end

    it "should show inbox message spec convert to string" do
      expectjs("'' + Routes.inbox_message_path").to eq('/inboxes/:inbox_id/messages/:id(.:format)')
    end
  end

  describe "requiredParams" do
    it "should show inbox spec" do
      expect(evaljs("Routes.inbox_path.requiredParams()").to_a).to eq(["id"])
    end

    it "should show inbox message spec" do
      expect(evaljs("Routes.inbox_message_path.requiredParams()").to_a).to eq(["inbox_id", "id"])
    end
  end
end
