require "rails_helper"

RSpec.describe Users::Delete, type: :service do
  let(:cache_bust) { instance_double(EdgeCache::Bust) }
  let(:user) { create(:user, :trusted, :with_identity, identities: ["github"]) }

  before do
    omniauth_mock_github_payload
    allow(Settings::Authentication).to receive(:providers).and_return(Authentication::Providers.available)
    allow(EdgeCache::Bust).to receive(:new).and_return(cache_bust)
    allow(cache_bust).to receive(:call)
  end

  it "deletes user" do
    described_class.call(user)
    expect(User.find_by(id: user.id)).to be_nil
  end

  it "busts user profile page" do
    described_class.new(user).call
    expect(cache_bust).to have_received(:call).with("/#{user.username}")
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

  it "deletes user's owned podcasts" do
    podcast = create(:podcast, creator: user)
    create(:podcast_ownership, owner: user, podcast: podcast)
    expect do
      described_class.call(user)
    end.to change(Podcast, :count).by(-1)
  end

  it "deletes the destroy token" do
    allow(Rails.cache).to receive(:delete).and_call_original
    described_class.call(user)
    expect(Rails.cache).to have_received(:delete).with("user-destroy-token-#{user.id}")
  end

  it "does not delete user's audit logs" do
    audit_log = create(:audit_log, user: user)

    expect do
      described_class.call(user)
    end.not_to change(AuditLog, :count)

    expect(audit_log.reload.user_id).to be_nil
  end

  it "deletes field tests memberships" do
    create(:field_test_membership, participant_id: user.id)

    expect do
      described_class.call(user)
    end.to change(FieldTest::Membership, :count).by(-1)
  end

  it "deletes reactions to the user" do
    create(:vomit_reaction, reactable: user)

    expect do
      described_class.call(user)
    end.to change(Reaction, :count).by(-1)
  end

  # check that all the associated records are being destroyed,
  # except for those that are kept explicitly (kept_associations)
  describe "deleting associations" do
    let(:kept_association_names) do
      %i[
        affected_feedback_messages
        audit_logs
        banished_users
        billboard_events
        created_podcasts
        feed_events
        offender_feedback_messages
        page_views
        rating_votes
        reporter_feedback_messages
        tweets
      ]
    end
    let(:direct_associations) do
      User.reflect_on_all_associations.reject do |a|
        a.options.key?(:join_table) || a.options.key?(:through)
      end
    end
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

          # Skip trying to create listings as the factory is removed
          next if possible_factory_name == "listing"

          inverse_of = association.options[:inverse_of] || association.options[:as] || :user

          # as we can't be automatically sure that the other side of the relation
          # has defined a `has_one` relation we need to guard against third party
          # models that don't have them defined
          model = class_name.safe_constantize
          if model && !model.reflect_on_association(inverse_of)
            next
          end

          next if possible_factory_name == "invited_by"

          record = create(possible_factory_name, inverse_of => user)
          associations.push(record)
        end
      end

      associations
    end

    it "keeps the kept associations" do
      # NB: each association must have a factory defined!
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

  context "when the user was suspended" do
    it "stores a hash of the username so the user can't sign up again" do
      user = create(:user, :suspended)
      expect do
        described_class.call(user)
      end.to change(Users::SuspendedUsername, :count).by(1)
    end
  end

  context "when the user was a spammer" do
    it "stores a hash of the username so the user can't sign up again" do
      user = create(:user, :spam)
      expect do
        described_class.call(user)
      end.to change(Users::SuspendedUsername, :count).by(1)
    end
  end
end
