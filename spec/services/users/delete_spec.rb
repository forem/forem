require "rails_helper"

RSpec.describe Users::Delete, type: :service do
  let(:user) { create(:user, :with_identity, identities: ["github"]) }

  it "deletes user" do
    described_class.call(user)
    expect(User.find_by(id: user.id)).to be_nil
  end

  it "busts user profile page" do
    allow(CacheBuster).to receive(:bust)
    described_class.new(user).call
    expect(CacheBuster).to have_received(:bust).with("/#{user.username}")
  end

  it "deletes user's follows" do
    create(:follow, follower: user)
    create(:follow, followable: user)

    expect do
      described_class.call(user)
    end.to change(Follow, :count).by(-2)
  end

  it "deletes user's articles" do
    article = create(:article, user: user)
    described_class.call(user)
    expect(Article.find_by(id: article.id)).to be_nil
  end

  it "deletes the destroy token" do
    allow(Rails.cache).to receive(:delete).and_call_original
    described_class.call(user)
    expect(Rails.cache).to have_received(:delete).with("user-destroy-token-#{user.id}")
  end

  # check that all the associated records are being destroyed, except for those that are kept explicitly (kept_associations)
  describe "deleting associations" do
    let(:kept_association_names) { %i[created_podcasts notes offender_feedback_messages reporter_feedback_messages affected_feedback_messages] }
    let(:direct_associations) { User.reflect_on_all_associations.reject { |a| a.options.key?(:join_table) || a.options.key?(:through) } }
    let!(:user_associations) do
      create_associations(direct_associations.reject { |a| kept_association_names.include?(a.name) })
    end
    let!(:kept_associations) do
      create_associations(direct_associations.select { |a| kept_association_names.include?(a.name) })
    end

    def create_associations(names)
      associations = []
      names.each do |association|
        if user.public_send(association.name).present?
          associations.push(*user.public_send(association.name))
        else
          singular_name = ActiveSupport::Inflector.singularize(association.name)
          class_name = association.options[:class_name] || singular_name
          possible_factory_name = class_name.underscore.tr("/", "_")
          inverse_of = association.options[:inverse_of] || association.options[:as] || :user
          record = create(possible_factory_name, inverse_of => user)
          associations.push record
        end
      end
      associations
    end

    it "keeps the kept associations" do
      expect(kept_associations).not_to be_empty
      user.reload
      described_class.call(user)
      aggregate_failures "associations should exist" do
        kept_associations.each do |kept_association|
          expect { kept_association.reload }.not_to raise_error
        end
      end
    end

    it "deletes all the associations" do
      # making sure that the association records were actually created
      expect(user_associations).not_to be_empty
      user.reload
      described_class.call(user)
      aggregate_failures "associations should not exist" do
        user_associations.each do |user_association|
          expect { user_association.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  context "when cleaning up chat channels" do
    let_it_be(:other_user) { create(:user) }

    it "deletes the user's private chat channels" do
      chat_channel = ChatChannel.create_with_users(users: [user, other_user])
      described_class.call(user)
      expect(ChatChannel.find_by(id: chat_channel.id)).to be_nil
    end

    it "does not delete the user's open channels" do
      chat_channel = ChatChannel.create_with_users(users: [user, other_user], channel_type: "open")
      described_class.call(user)
      expect(ChatChannel.find_by(id: chat_channel.id)).not_to be_nil
    end
  end
end
