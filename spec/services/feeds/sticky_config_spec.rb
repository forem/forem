require "rails_helper"

RSpec.describe Feeds::StickyConfig do
  let(:user) { create(:user) }
  let(:config) { create(:feed_config, feed_impression_users_count: 2) }

  before do
    allow(Settings::UserExperience).to receive_messages(
      feed_config_sticky_hours: 60, feed_config_sticky_percentage: 50, feed_config_repeat_visit_minutes: 30,
    )
    allow(FeedConfig).to receive(:select_for_feed).with(
      user: user, context_type: FeedEvent::CONTEXT_TYPE_HOME,
    ).and_return(config)
  end

  def sticky_selector(subforem_id: nil)
    described_class.new(user: user, subforem_id: subforem_id).tap do |selector|
      allow(selector).to receive(:rand).with(100).and_return(0)
    end
  end

  def record_visit(selector, event_id: SecureRandom.uuid)
    Feeds::RecordConfigVisit.call(token: selector.visit_token(host: "forem.test"), event_id: event_id,
                                  user_id: user.id, host: "forem.test")
  end

  describe "selection" do
    it "starts a fixed 60-hour assignment without rewarding the initial load" do
      Timecop.freeze(Time.current.change(nsec: 123_456_789)) do
        selector = sticky_selector
        expect(selector.select).to eq(config)
        record_visit(selector)

        expect(FeedConfigAssignment.find_by!(user: user)).to have_attributes(
          feed_config_id: config.id,
          expires_at: be_within(0.000001).of(60.hours.from_now),
          last_rewarded_at: be_within(0.000001).of(Time.current),
        )
        expect(config.reload.feed_repeat_visits_count).to eq(0)
      end
    end

    it "reuses the assigned config while still selecting ordinary variations on the other half of loads" do
      create(:feed_config_assignment, user: user, feed_config: config)
      alternative = create(:feed_config)
      allow(FeedConfig).to receive(:select_for_feed).and_return(alternative)

      expect(sticky_selector.select).to eq(config)
      selector = sticky_selector
      allow(selector).to receive(:rand).with(100).and_return(50)
      expect(selector.select).to eq(alternative)
      record_visit(selector)
      expect(config.reload.feed_repeat_visits_count).to eq(0)
    end

    it "honors a configurable traffic percentage at its boundary" do
      create(:feed_config_assignment, user: user, feed_config: config)
      alternative = create(:feed_config)
      allow(FeedConfig).to receive(:select_for_feed).and_return(alternative)
      allow(Settings::UserExperience).to receive(:feed_config_sticky_percentage).and_return(25)
      selector = sticky_selector
      allow(selector).to receive(:rand).with(100).and_return(24)
      expect(selector.select).to eq(config)
      selector = sticky_selector
      allow(selector).to receive(:rand).with(100).and_return(25)
      expect(selector.select).to eq(alternative)
    end

    it "supports a custom assignment duration" do
      allow(Settings::UserExperience).to receive(:feed_config_sticky_hours).and_return(12)
      Timecop.freeze(Time.current.change(nsec: 123_456_789)) do
        sticky_selector.select
        expect(FeedConfigAssignment.find_by!(user: user).expires_at).to be_within(0.000001).of(12.hours.from_now)
      end
    end

    it "leaves selection unchanged when duration is zero" do
      allow(Settings::UserExperience).to receive(:feed_config_sticky_hours).and_return(0)
      expect { expect(sticky_selector.select).to eq(config) }.not_to change(FeedConfigAssignment, :count)
    end

    it "leaves selection unchanged when the sticky percentage is zero" do
      allow(Settings::UserExperience).to receive(:feed_config_sticky_percentage).and_return(0)
      expect { expect(sticky_selector.select).to eq(config) }.not_to change(FeedConfigAssignment, :count)
    end

    it "reassigns at expiry and starts a fresh cooldown and repeat counter even if the same config is selected" do
      Timecop.freeze(Time.current.change(nsec: 123_456_789)) do
        assignment = create(:feed_config_assignment, user: user, feed_config: config,
                                                     expires_at: Time.current, last_rewarded_at: 1.hour.ago,
                                                     repeat_visits_count: 20)
        selector = sticky_selector
        selector.select
        record_visit(selector)

        expect(assignment.reload).to have_attributes(
          expires_at: be_within(0.000001).of(60.hours.from_now),
          repeat_visits_count: 0,
        )
        expect(config.reload.feed_repeat_visits_count).to eq(0)
      end
    end

    it "replaces an archived assignment with an active config" do
      archived = create(:feed_config, archived: true)
      assignment = create(:feed_config_assignment, user: user, feed_config: archived)
      expect(sticky_selector.select).to eq(config)
      expect(assignment.reload.feed_config).to eq(config)
    end

    it "recovers after an assigned config is deleted" do
      deleted = create(:feed_config)
      assignment = create(:feed_config_assignment, user: user, feed_config: deleted)
      deleted.destroy!

      expect(sticky_selector.select).to eq(config)
      expect(assignment.reload.feed_config).to eq(config)
    end

    it "does not persist a stub assignment with nil feed_config_id or expires_at if selection fails" do
      selector = sticky_selector
      allow(selector).to receive(:select_active_config).and_raise(ActiveRecord::StatementInvalid, "aborted")

      expect { selector.select }.to raise_error(ActiveRecord::StatementInvalid, "aborted")
      expect(FeedConfigAssignment.where(user: user)).to be_empty
      expect(selector.visit_token(host: "forem.test")).to be_nil
    end

    it "heals a legacy incomplete assignment row and never generates a visit token when incomplete" do
      stub_assignment = create(:feed_config_assignment, user: user, feed_config: nil, expires_at: nil)
      expect(stub_assignment.visit_token(host: "forem.test")).to be_nil

      selector = sticky_selector
      expect(selector.select).to eq(config)
      expect(stub_assignment.reload).to have_attributes(
        feed_config_id: config.id,
        expires_at: be_present,
      )
      expect(selector.visit_token(host: "forem.test")).to be_present
    end

    it "isolates assignments by user and subforem" do
      other_user = create(:user)
      create(:feed_config_assignment, user: other_user, feed_config: config)
      subforem = create(:subforem)

      sticky_selector.select
      sticky_selector(subforem_id: subforem.id).select

      expect(FeedConfigAssignment.where(user: user).pluck(:subforem_id)).to contain_exactly(nil, subforem.id)
      expect(FeedConfigAssignment.where(user: other_user).count).to eq(1)
    end

    it "reuses an active unexpired assignment without acquiring advisory or row locks" do
      create(:feed_config_assignment, user: user, feed_config: config, expires_at: 1.hour.from_now)
      queries = []
      callback = ->(_name, _start, _finish, _id, payload) { queries << payload[:sql] unless payload[:name] == "SCHEMA" }

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        expect(sticky_selector.select).to eq(config)
      end

      expect(queries.grep(/pg_advisory_xact_lock|FOR UPDATE|SAVEPOINT/)).to be_empty
    end

    it "does not query feed_configs with IS NULL when no assignment exists yet" do
      queries = []
      callback = ->(_name, _start, _finish, _id, payload) { queries << payload[:sql] unless payload[:name] == "SCHEMA" }

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        expect(sticky_selector.select).to eq(config)
      end

      expect(queries.grep(/FROM "feed_configs".*"id" IS NULL/)).to be_empty
    end
  end

  context "with concurrent requests" do
    self.use_transactional_tests = false

    after do
      user.destroy!
      config.destroy!
    end

    def wait_for_database_lock(pid)
      Timeout.timeout(10) do
        loop do
          blockers = ActiveRecord::Base.connection.select_value("SELECT cardinality(pg_blocking_pids(#{Integer(pid)}))")
          break if blockers.positive?

          sleep 0.01
        end
      end
    end

    it "protects an uncommitted assignment when archival starts before the assignment is visible" do
      config.update!(created_at: 3.days.ago)
      stub_const("FeedConfig::ARCHIVE_TOP_LIMIT", 0)
      selector = sticky_selector
      selected = Queue.new
      release = Queue.new
      archive_pid = Queue.new
      allow(selector).to receive(:select_active_config).and_wrap_original do |method|
        method.call.tap do
          selected << true
          release.pop
        end
      end

      selection = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection { selector.select }
      end
      Timeout.timeout(10) { selected.pop }
      archival = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do |connection|
          archive_pid << connection.raw_connection.backend_pid
          FeedConfig.archive_stale_configs!
        end
      end
      wait_for_database_lock(Timeout.timeout(10) { archive_pid.pop })
      expect(FeedConfigAssignment.where(user: user).pick(:feed_config_id)).to be_nil
      release << true
      expect(selection.value).to eq(config)
      archival.value

      expect(config.reload).not_to be_archived
      expect(FeedConfigAssignment.find_by!(user: user).feed_config_id).to eq(config.id)
      expect(record_visit(selector)).to be_present
    ensure
      release << true
      [selection, archival].compact.each { |thread| thread.join(10) || thread.kill }
    end

    it "reselects when archival commits while selection is waiting for the config lock" do
      alternative = create(:feed_config)
      selector = sticky_selector
      allow(FeedConfig).to receive(:select_for_feed).and_return(config, alternative)
      selection_pid = Queue.new
      selection = nil

      config.with_lock do
        config.update!(archived: true)
        selection = Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do |connection|
            selection_pid << connection.raw_connection.backend_pid
            selector.select
          end
        end
        wait_for_database_lock(Timeout.timeout(10) { selection_pid.pop })
      end

      expect(selection.value).to eq(alternative)
      expect(FeedConfigAssignment.find_by!(user: user).feed_config_id).to eq(alternative.id)
      expect(record_visit(selector)).to be_present
    ensure
      selection&.join(10) || selection&.kill
      alternative&.destroy!
    end

    it "creates only one assignment when first loads arrive on separate connections" do
      selectors = Array.new(2) { sticky_selector }
      start = Queue.new
      threads = selectors.map do |selector|
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            start.pop
            selector.select
          end
        end
      end
      threads.size.times { start << true }
      expect(threads.map(&:value)).to eq([config, config])
      expect(FeedConfigAssignment.where(user: user).count).to eq(1)
    end

    it "awards only one return across separate database connections" do
      create(:feed_config_assignment, user: user, feed_config: config, last_rewarded_at: 1.hour.ago)
      selectors = Array.new(2) { sticky_selector.tap(&:select) }
      start = Queue.new
      threads = selectors.map do |selector|
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            start.pop
            record_visit(selector)
          end
        end
      end
      threads.size.times { start << true }
      threads.each(&:value)

      expect(config.reload.feed_repeat_visits_count).to eq(1)
      expect(config.feed_success_score).to eq(0.5)
    end
  end

  describe "repeat credit" do
    it "allows at most 20 repeat credits in a 60-hour assignment window" do
      Timecop.freeze do
        started_at = Time.current
        selector = sticky_selector
        selector.select
        record_visit(selector)

        1.upto(120) do |interval|
          Timecop.freeze(started_at + (interval * 30).minutes) { record_visit(selector) }
        end

        expect(config.reload.feed_repeat_visits_count).to eq(20)
        expect(FeedConfigAssignment.find_by!(user: user).repeat_visits_count).to eq(20)
      end
    end

    it "credits returns at 30-minute intervals without extending the assignment" do
      Timecop.freeze do
        selector = sticky_selector
        selector.select
        record_visit(selector)
        expiry = FeedConfigAssignment.find_by!(user: user).expires_at

        Timecop.freeze(30.minutes.from_now) do
          record_visit(selector)
          expect(config.reload.feed_repeat_visits_count).to eq(1)
          expect(config.feed_success_score).to eq(0.5)
          expect(FeedConfigAssignment.find_by!(user: user).expires_at).to eq(expiry)
        end
        Timecop.freeze(60.minutes.from_now) do
          record_visit(selector)
          expect(config.reload.feed_repeat_visits_count).to eq(2)
          expect(config.feed_success_score).to eq(1.0)
        end
      end
    end

    it "awards 1.5 clicks per repeat visit for feed_power_user configurations" do
      config.update!(targeting_bucket: FeedConfig::BUCKET_FEED_POWER_USER)
      Timecop.freeze do
        selector = sticky_selector
        selector.select
        record_visit(selector)

        Timecop.freeze(30.minutes.from_now) do
          record_visit(selector)
          expect(config.reload).to have_attributes(
            feed_repeat_visits_count: 1,
            feed_success_score: 0.75,
          )
        end
      end
    end

    it "enforces a rolling cooldown rather than allowing two rewards across a clock boundary" do
      Timecop.freeze do
        assignment = create(:feed_config_assignment, user: user, feed_config: config,
                                                     last_rewarded_at: 29.minutes.ago)
        selector = sticky_selector
        selector.select
        expect { record_visit(selector) }.not_to change { config.reload.feed_repeat_visits_count }

        assignment.update!(last_rewarded_at: 30.minutes.ago)
        expect { record_visit(selector) }.to change { config.reload.feed_repeat_visits_count }.by(1)
      end
    end

    it "uses a configurable cooldown" do
      allow(Settings::UserExperience).to receive(:feed_config_repeat_visit_minutes).and_return(60)
      create(:feed_config_assignment, user: user, feed_config: config, last_rewarded_at: 45.minutes.ago)
      selector = sticky_selector
      selector.select
      expect { record_visit(selector) }.not_to change { config.reload.feed_repeat_visits_count }
    end

    it "does not double-count requests holding stale copies of the same assignment" do
      create(:feed_config_assignment, user: user, feed_config: config, last_rewarded_at: 31.minutes.ago)
      first = sticky_selector
      second = sticky_selector
      first.select
      second.select

      expect do
        record_visit(first)
        record_visit(second)
      end.to change { config.reload.feed_repeat_visits_count }.by(1)
    end

    it "does not credit a load that finishes after its assignment expires" do
      create(:feed_config_assignment, user: user, feed_config: config, last_rewarded_at: 1.hour.ago)
      selector = sticky_selector
      selector.select

      Timecop.travel(60.hours.from_now) do
        expect { record_visit(selector) }.not_to change { config.reload.feed_repeat_visits_count }
      end
    end

    it "does not credit a stale request after its assignment changes" do
      assignment = create(:feed_config_assignment, user: user, feed_config: config, last_rewarded_at: 1.hour.ago)
      selector = sticky_selector
      selector.select
      assignment.update!(feed_config: create(:feed_config))

      expect { record_visit(selector) }.not_to change { config.reload.feed_repeat_visits_count }
    end
  end
end
