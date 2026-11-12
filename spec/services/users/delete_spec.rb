require "rails_helper"

RSpec.describe Users::Delete, type: :service do
  let(:user) { create(:user) }

  def create(name, *traits, **options)
    if name == :user
      options[:profile_image] = nil unless options.key?(:profile_image)
    elsif name == :article
      options[:with_tags] = false unless options.key?(:tag_list) || options.key?(:tags) || options.key?(:with_tags)
      options[:with_main_image] = false unless options.key?(:with_main_image)
    end
    super(name, *traits, **options)
  end

  before do
    allow(EdgeCache::BustUser).to receive(:call)
  end

  it "deletes the user, removes from Mailchimp, clears the destroy token, and enqueues a delayed profile purge",
     :aggregate_failures do
    profile_keys = user.profile_cache_keys
    profile_paths = user.profile_cache_bust_paths
    allow(user).to receive(:remove_from_mailchimp_newsletters)
    allow(Rails.cache).to receive(:delete).and_call_original

    sidekiq_assert_enqueued_with(
      job: EdgeCache::PurgeByKeyWorker,
      args: [profile_keys, profile_paths],
    ) do
      described_class.call(user)
    end

    expect(User.find_by(id: user.id)).to be_nil
    expect(user).to have_received(:remove_from_mailchimp_newsletters).once
    expect(Rails.cache).to have_received(:delete).with("user-destroy-token-#{user.id}")

    job = EdgeCache::PurgeByKeyWorker.jobs.detect { |j| j["args"].first == profile_keys }
    expect(job["at"]).to be > Time.current.to_f
  end

  it "retries deletion if a concurrent AiAudit triggers InvalidForeignKey" do
    attempts = 0
    original_method = user.method(:destroy)
    allow(user).to receive(:destroy) do
      attempts += 1
      raise ActiveRecord::InvalidForeignKey, "violates foreign key constraint on table ai_audits" if attempts == 1

      original_method.call
    end

    described_class.call(user)
    expect(User.find_by(id: user.id)).to be_nil
    expect(attempts).to eq(2)
  end

  it "recovers from a real ai_audits foreign key violation inside the destroy transaction" do
    attempts = 0
    original_method = user.method(:destroy)
    allow(user).to receive(:destroy) do
      attempts += 1
      # a real violation aborts the surrounding transaction unless it's in a savepoint
      create(:ai_audit, affected_user_id: -1) if attempts == 1
      original_method.call
    end

    described_class.call(user)

    expect(User.find_by(id: user.id)).to be_nil
    expect(attempts).to eq(2)
  end

  it "keeps the user when the final profile purge can't be enqueued, so a retry can finish the job" do
    allow(EdgeCache::PurgeByKeyWorker).to receive(:perform_in).and_call_original
    allow(EdgeCache::PurgeByKeyWorker).to receive(:perform_in)
      .with(anything, user.profile_cache_keys, user.profile_cache_bust_paths)
      .and_raise(Redis::CannotConnectError)

    expect { described_class.call(user) }.to raise_error(Redis::CannotConnectError)
    expect(User.exists?(user.id)).to be(true)

    allow(EdgeCache::PurgeByKeyWorker).to receive(:perform_in).and_call_original
    sidekiq_assert_enqueued_with(
      job: EdgeCache::PurgeByKeyWorker,
      args: [user.profile_cache_keys, user.profile_cache_bust_paths],
    ) do
      described_class.call(User.find(user.id))
    end
    expect(User.exists?(user.id)).to be(false)
  end

  describe "the post-destroy block" do
    it "keeps the user when the block fails and runs after the user is destroyed on retry", :aggregate_failures do
      expect do
        described_class.call(user) { raise ActiveRecord::QueryCanceled }
      end.to raise_error(ActiveRecord::QueryCanceled)
      expect(User.exists?(user.id)).to be(true)

      user_existed_in_block = nil
      described_class.call(User.find(user.id)) { user_existed_in_block = User.exists?(user.id) }

      expect(user_existed_in_block).to be(false)
      expect(User.exists?(user.id)).to be(false)
    end
  end

  it "raises instead of carrying on when the destroy is aborted" do
    allow(user).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed)
    block_ran = false

    expect do
      described_class.call(user) { block_ran = true }
    end.to raise_error(ActiveRecord::RecordNotDestroyed)
    expect(block_ran).to be(false)
  end

  it "purges the user's profile when the enqueued jobs run" do
    allow(EdgeCache::PurgeByKey).to receive(:call)
    keys = user.profile_cache_keys
    paths = user.profile_cache_bust_paths

    sidekiq_perform_enqueued_jobs { described_class.call(user) }

    expect(EdgeCache::PurgeByKey).to have_received(:call).with(keys, fallback_paths: paths)
  end

  it "can be re-run to finish a deletion that failed part way through" do
    article = create(:article, user: user)
    create(:comment, user: user, commentable: article)
    allow(Users::DeletePodcasts).to receive(:call).and_raise(ActiveRecord::QueryCanceled)

    expect { described_class.call(user) }.to raise_error(ActiveRecord::QueryCanceled)
    expect(User.exists?(user.id)).to be(true)
    expect(Article.exists?(article.id)).to be(false)

    allow(Users::DeletePodcasts).to receive(:call).and_call_original
    described_class.call(User.find(user.id))

    expect(User.exists?(user.id)).to be(false)
  end

  it "deletes user's follows, content, podcasts, activity, memberships, and reactions without busting caches inline",
     :aggregate_failures do
    other_user = create(:user, :without_profile, :trusted)
    create(:follow, follower: user, followable: other_user)
    create(:follow, followable: user, follower: other_user)
    article = create(:article, user: user)
    comment = create(:comment, user: user, commentable: article)
    podcast = create(:podcast, creator: user)
    create(:podcast_ownership, owner: user, podcast: podcast)
    user.user_activity || create(:user_activity, user: user)
    create(:field_test_membership, participant_id: user.id)
    create(:vomit_reaction, reactable: user, user: other_user)

    allow(EdgeCache::PurgeByKey).to receive(:call)
    allow(EdgeCache::Bust).to receive(:call)
    allow(EdgeCache::BustArticle).to receive(:call)
    allow(EdgeCache::BustComment).to receive(:call)

    expect do
      described_class.call(user)
    end.to change(Follow, :count).by(-2)
      .and change(Podcast, :count).by(-1)
      .and change(UserActivity, :count).by(-1)
      .and change(FieldTest::Membership, :count).by(-1)
      .and change(Reaction, :count).by(-1)

    expect(Article.find_by(id: article.id)).to be_nil
    expect(Comment.find_by(id: comment.id)).to be_nil
    expect(EdgeCache::PurgeByKey).not_to have_received(:call)
    expect(EdgeCache::Bust).not_to have_received(:call)
    expect(EdgeCache::BustArticle).not_to have_received(:call)
    expect(EdgeCache::BustComment).not_to have_received(:call)
    expect(EdgeCache::BustUser).not_to have_received(:call)
  end

  it "preserves audit_logs, ai_audits, and favorited content while nullifying user references",
     :aggregate_failures do
    other_user = create(:user, :without_profile)
    audit_log = create(:audit_log, user: user)
    ai_audit = create(:ai_audit, affected_user_id: user.id)
    article = create(:article, user: other_user, favorited_by_user: user, favorited_at: Time.current)
    comment = create(:comment, commentable: article, user: other_user, favorited_by_user: user,
                               favorited_at: Time.current)

    expect do
      described_class.call(user)
    end.to not_change(AuditLog, :count).and not_change(AiAudit, :count)

    expect(audit_log.reload.user_id).to be_nil
    expect(ai_audit.reload.affected_user_id).to be_nil
    expect(article.reload.favorited_by_user_id).to be_nil
    expect(comment.reload.favorited_by_user_id).to be_nil
  end

  # check that all the associated records are being destroyed,
  # except for those that are kept explicitly (kept_associations)
  describe "deleting associations" do
    let(:user) { create(:user, :trusted, :with_identity, identities: ["github"]) }
    let(:other_user) { create(:user, :without_profile) }
    let(:blocked_user) { create(:user, :without_profile) }
    let(:other_article) do
      create(:article, :with_user_subscription_tag_role_user, user: other_user, with_user_subscription_tag: true)
    end
    let(:favorited_article) { create(:article, user: other_user, favorited_by_user: user) }
    let(:shared_poll) { create(:poll, article: other_article) }
    let(:shared_factory_defaults) do
      {
        "article" => { user: other_user },
        "co_author_invitation" => { article: other_article },
        "comment" => { commentable: other_article, user: other_user },
        "discussion_lock" => { article: favorited_article },
        "feed_event" => { article: other_article },
        "flag_appeal" => { appealable: other_user },
        "follow" => { follower: other_user, followable: other_user },
        "mention" => { mentionable: other_article },
        "note" => { author: other_user, noteable: other_user },
        "notification" => { notifiable: other_article, organization: nil },
        "notification_subscription" => { notifiable: other_article },
        "page_view" => { article: other_article },
        "poll" => { article: other_article },
        "poll_skip" => { poll: shared_poll },
        "poll_text_response" => { poll: shared_poll },
        "poll_vote" => { poll: shared_poll, poll_option: shared_poll.poll_options.first },
        "rating_vote" => { article: other_article },
        "reaction" => { reactable: other_article },
        "user_block" => { blocker: blocked_user, blocked: blocked_user },
        "user_subscription" => {
          author: other_user,
          subscriber: other_user,
          user_subscription_sourceable: other_article
        }
      }
    end
    let(:kept_association_names) do
      %i[
        affected_feedback_messages
        ai_audits
        audit_logs
        banished_users
        billboard_events
        created_podcasts
        favorited_articles
        favorited_comments
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
    let(:user_associations) do
      create_associations(direct_associations.reject { |a| kept_association_names.include?(a.name) })
    end
    let(:kept_associations) do
      create_associations(direct_associations.select { |a| kept_association_names.include?(a.name) })
    end

    before do
      omniauth_mock_github_payload
      allow(Settings::Authentication).to receive(:providers).and_return(Authentication::Providers.available)
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

          # Skip scheduled_automations as they require a community bot user
          next if possible_factory_name == "scheduled_automation"

          # Skip feeds models — factory names don't match auto-generated names
          next if possible_factory_name.start_with?("feeds_")

          inverse_of = association.options[:inverse_of] || association.options[:as] || :user

          # as we can't be automatically sure that the other side of the relation
          # has defined a `has_one` relation we need to guard against third party
          # models that don't have them defined
          model = class_name.safe_constantize
          if model && !model.reflect_on_association(inverse_of)
            next
          end

          next if possible_factory_name == "invited_by"

          record = create(possible_factory_name, **association_factory_options(possible_factory_name, inverse_of))
          associations.push(record)
        end
      end

      associations
    end

    def association_factory_options(factory_name, inverse_of)
      defaults = if factory_name == "profile_pin"
                   { pinnable: user.articles.first || create(:article, user: user) }
                 else
                   shared_factory_defaults.fetch(factory_name, {})
                 end
      defaults.merge(inverse_of => user)
    end

    it "deletes all the associations and keeps the kept associations" do
      # making sure that the association records were actually created
      # NB: each association must have a factory defined!
      expect(user_associations).not_to be_empty
      expect(kept_associations).not_to be_empty
      user.reload
      described_class.call(user)
      aggregate_failures "associations should not exist" do
        user_associations.each do |user_association|
          expect { user_association.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
      aggregate_failures "kept associations should exist" do
        kept_associations.each do |kept_association|
          expect { kept_association.reload }.not_to raise_error
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
