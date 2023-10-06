require "rails_helper"

RSpec.describe Ahoy::Store do
  let(:user) { create(:user) }
  let(:data) { { user_id: user.id, started_at: Time.current } }
  let(:mock_request) { instance_double("Request", headers: { "X-Client-Geo" => "mock_geo", "HTTP_ACCEPT_LANGUAGE" => "mock_language" }, user_agent: "mock_user_agent") }

  # Create a real instance of Ahoy::Store to test behavior
  let(:store) { described_class.new(request: mock_request) }

  before do
    allow(mock_request).to receive(:user_agent).and_return("mock_user_agent")
  end

  describe "#track_visit" do
    context "when context is not found" do
      it "creates a new UserVisitContext and increments visit count" do
        expect { store.track_visit(data) }.to change(UserVisitContext, :count).by(1)

        context = UserVisitContext.last
        expect(context.visit_count).to eq(1)
        expect(context.last_visit_at).to be_within(1.second).of(data[:started_at])
      end
    end

    context "when context is found" do
      let!(:existing_context) do
        create(:user_visit_context,
               geolocation: "mock_geo",
               user_agent: "mock_user_agent",
               accept_language: "mock_language",
               user_id: user.id,
               visit_count: 5)
      end

      it "increments the visit count" do
        expect { store.track_visit(data) }.not_to change(UserVisitContext, :count)
        expect(existing_context.reload.visit_count).to eq(6)
      end

      it "updates the last_visit_at timestamp" do
        store.track_visit(data)
        expect(existing_context.reload.last_visit_at).to be_within(1.second).of(data[:started_at])
      end
    end

    it "calls super with the correct data including context id" do
      context = create(:user_visit_context, user: user)
      allow(UserVisitContext).to receive(:find_or_initialize_by).and_return(context)

      expect_any_instance_of(Ahoy::DatabaseStore).to receive(:track_visit).with(hash_including(user_visit_context_id: context.id))

      store.track_visit(data)
    end
  end
end
