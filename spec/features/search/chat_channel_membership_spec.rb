require "rails_helper"

RSpec.describe Search::ChatChannelMembership, type: :feature, elasticsearch: true do
  let(:user) { create(:user) }
  let(:chat_channel_membership1) { create(:chat_channel_membership, user_id: user.id) }
  let(:chat_channel_membership2) { create(:chat_channel_membership, user_id: user.id) }

  def index_documents(resources)
    resources.each(&:index_to_elasticsearch_inline)
    described_class.refresh_index
  end

  context "with a query" do
    it "searches by channel_text" do
      allow(chat_channel_membership1).to receive(:channel_text).and_return("a name")
      allow(chat_channel_membership2).to receive(:channel_text).and_return("another name and slug")
      index_documents([chat_channel_membership1, chat_channel_membership2])
      name_params = { size: 5, channel_text: "name" }

      chat_channel_membership_docs = described_class.search_documents(params: name_params, user_id: user.id)
      expect(chat_channel_membership_docs.count).to eq(2)
      doc_ids = chat_channel_membership_docs.map { |t| t.dig("id") }
      expect(doc_ids).to include(chat_channel_membership1.id, chat_channel_membership2.id)
    end
  end

  context "with a filter" do
    it "searches by viewable_by" do
      new_user = create(:user)
      chat_channel_membership3 = create(:chat_channel_membership, user_id: new_user.id)
      index_documents([chat_channel_membership1, chat_channel_membership2, chat_channel_membership3])
      params = { size: 5 }

      chat_channel_membership_docs = described_class.search_documents(params: params, user_id: new_user.id)
      expect(chat_channel_membership_docs.count).to eq(1)
      expect(chat_channel_membership_docs.first["id"]).to eq(chat_channel_membership3.id)
    end

    it "searches by channel_status" do
      allow(chat_channel_membership1).to receive(:channel_status).and_return("popping")
      index_documents([chat_channel_membership1, chat_channel_membership2])
      params = { size: 5, channel_status: "popping" }

      chat_channel_membership_docs = described_class.search_documents(params: params, user_id: user.id)
      expect(chat_channel_membership_docs.count).to eq(1)
      expect(chat_channel_membership_docs.first["id"]).to eq(chat_channel_membership1.id)
    end

    it "searches by channel_type" do
      allow(chat_channel_membership2).to receive(:channel_type).and_return("invite_only")
      index_documents([chat_channel_membership1, chat_channel_membership2])
      params = { size: 5, channel_type: "invite_only" }

      chat_channel_membership_docs = described_class.search_documents(params: params, user_id: user.id)
      expect(chat_channel_membership_docs.count).to eq(1)
      expect(chat_channel_membership_docs.first["id"]).to eq(chat_channel_membership2.id)
    end

    it "searches by status" do
      chat_channel_membership1.update(status: "inactive")
      chat_channel_membership2.update(status: "active")
      index_documents([chat_channel_membership1, chat_channel_membership2])
      params = { size: 5, status: "active" }

      chat_channel_membership_docs = described_class.search_documents(params: params, user_id: user.id)
      expect(chat_channel_membership_docs.count).to eq(1)
      expect(chat_channel_membership_docs.first["id"]).to eq(chat_channel_membership2.id)
    end
  end

  it "sorts documents for given field" do
    chat_channel_membership1.update(status: "inactive")
    chat_channel_membership2.update(status: "active")
    index_documents([chat_channel_membership1, chat_channel_membership2])
    params = { size: 5, sort_by: "status", sort_direction: "asc" }

    chat_channel_membership_docs = described_class.search_documents(params: params, user_id: user.id)
    expect(chat_channel_membership_docs.count).to eq(2)
    expect(chat_channel_membership_docs.first["id"]).to eq(chat_channel_membership2.id)
    expect(chat_channel_membership_docs.last["id"]).to eq(chat_channel_membership1.id)
  end

  it "sorts documents by channel_last_message_at by default" do
    allow(chat_channel_membership1).to receive(:channel_last_message_at).and_return(Time.current)
    allow(chat_channel_membership2).to receive(:channel_last_message_at).and_return(1.year.ago)
    index_documents([chat_channel_membership1, chat_channel_membership2])
    params = { size: 5 }

    chat_channel_membership_docs = described_class.search_documents(params: params, user_id: user.id)
    expect(chat_channel_membership_docs.count).to eq(2)
    expect(chat_channel_membership_docs.first["id"]).to eq(chat_channel_membership1.id)
    expect(chat_channel_membership_docs.last["id"]).to eq(chat_channel_membership2.id)
  end
end
