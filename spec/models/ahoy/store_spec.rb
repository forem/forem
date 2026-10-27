require "rails_helper"

RSpec.describe Ahoy::Store do
  let(:user) { create(:user) }
  let(:data) { { user_id: user.id, started_at: Time.current } }
  let(:mock_request) do
    instance_double(
      ActionDispatch::Request,
      headers: { "X-Client-Geo" => "mock_geo", "HTTP_ACCEPT_LANGUAGE" => "mock_language" },
      user_agent: "mock_user_agent",
    )
  end

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

    context "when a concurrent request creates the same UserVisitContext before save!" do
      it "rescues ActiveRecord::RecordNotUnique, reloads the existing context, and increments visit_count" do
        raced_context = build(:user_visit_context,
                              geolocation: "mock_geo",
                              user_agent: "mock_user_agent",
                              accept_language: "mock_language",
                              user_id: user.id,
                              visit_count: 0)
        persisted_context = create(:user_visit_context,
                                   geolocation: "mock_geo",
                                   user_agent: "mock_user_agent",
                                   accept_language: "mock_language",
                                   user_id: user.id,
                                   visit_count: 1)

        allow(UserVisitContext).to receive(:find_or_initialize_by).and_return(raced_context)
        allow(raced_context).to receive(:save!).and_raise(ActiveRecord::RecordNotUnique)

        store.track_visit(data)

        expect(persisted_context.reload.visit_count).to eq(2)
        expect(persisted_context.last_visit_at).to be_within(1.second).of(data[:started_at])
        expect(data[:user_visit_context_id]).to eq(persisted_context.id)
      end
    end

    it "calls super with the correct data including context id" do
      context = create(:user_visit_context, user: user)
      allow(UserVisitContext).to receive(:find_or_initialize_by).and_return(context)

      store.track_visit(data)

      expect(Ahoy::Visit.last.user_visit_context_id).to eq(context.id)
    end
  end
end
