require "rails_helper"

RSpec.describe EventMembership do
  describe "associations" do
    it { is_expected.to belong_to(:parent_event).class_name("Event") }
    it { is_expected.to belong_to(:child_event).class_name("Event") }
  end

  describe "validations and safeguards" do
    let(:conference) { create(:event, type_of: :conference, title: "DevConf") }
    let(:livestream) { create(:event, type_of: :live_stream, title: "Keynote Stream") }

    it "allows valid many-to-many relationships including diamond DAGs" do
      second_conf = create(:event, type_of: :conference, title: "Partner Summit")
      track_a = create(:event, type_of: :other, title: "Track A")
      track_b = create(:event, type_of: :other, title: "Track B")
      shared_session = create(:event, type_of: :live_stream, title: "Joint Session")

      create(:event_membership, parent_event: conference, child_event: livestream, role: "  Keynote  ")
      create(:event_membership, parent_event: second_conf, child_event: livestream, role: "Partner Stream")

      # Diamond: conference -> track_a -> shared_session AND conference -> track_b -> shared_session
      create(:event_membership, parent_event: conference, child_event: track_a)
      create(:event_membership, parent_event: conference, child_event: track_b)
      create(:event_membership, parent_event: track_a, child_event: shared_session)
      diamond_edge = build(:event_membership, parent_event: track_b, child_event: shared_session)

      expect(diamond_edge).to be_valid
      expect(diamond_edge.save).to be(true)
      expect(livestream.parent_events).to contain_exactly(conference, second_conf)
      expect(conference.child_event_memberships.find_by(child_event: livestream).role).to eq("Keynote")
    end

    it "rejects self-membership" do
      membership = build(:event_membership, parent_event: conference, child_event: conference)
      expect(membership).not_to be_valid
      expect(membership.errors[:child_event_id]).to include(I18n.t("models.event_membership.cannot_belong_to_self"))
    end

    it "rejects duplicate parent-child pairs" do
      create(:event_membership, parent_event: conference, child_event: livestream)
      duplicate = build(:event_membership, parent_event: conference, child_event: livestream)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:child_event_id]).to include(I18n.t("models.event_membership.already_member"))
    end

    it "rejects direct two-node cycles" do
      create(:event_membership, parent_event: conference, child_event: livestream)
      reverse = build(:event_membership, parent_event: livestream, child_event: conference)

      expect(reverse).not_to be_valid
      expect(reverse.errors[:child_event_id]).to include(I18n.t("models.event_membership.would_create_cycle"))
    end

    it "rejects multi-hop indirect cycles" do
      level_b = create(:event, title: "Track B")
      level_c = create(:event, title: "Session C")

      create(:event_membership, parent_event: conference, child_event: level_b)
      create(:event_membership, parent_event: level_b, child_event: level_c)

      closing_cycle = build(:event_membership, parent_event: level_c, child_event: conference)
      expect(closing_cycle).not_to be_valid
      expect(closing_cycle.errors[:child_event_id]).to include(I18n.t("models.event_membership.would_create_cycle"))
    end

    it "enforces maximum hierarchy depth" do
      events = create_list(:event, described_class::MAX_DEPTH + 2)
      described_class::MAX_DEPTH.times do |i|
        create(:event_membership, parent_event: events[i], child_event: events[i + 1])
      end

      too_deep = build(:event_membership,
                       parent_event: events[described_class::MAX_DEPTH],
                       child_event: events[described_class::MAX_DEPTH + 1])
      expect(too_deep).not_to be_valid
      expect(too_deep.errors[:base]).to include(
        I18n.t("models.event_membership.max_depth_exceeded", max: described_class::MAX_DEPTH),
      )
    end

    it "validates position and role length" do
      neg_pos = build(:event_membership, parent_event: conference, child_event: livestream, position: -1)
      expect(neg_pos).not_to be_valid

      long_role = build(:event_membership, parent_event: conference, child_event: livestream, role: "a" * 65)
      expect(long_role).not_to be_valid
    end

    it "acquires the hierarchy advisory lock before cycle validation on save" do
      allow(described_class).to receive(:acquire_hierarchy_write_lock!).and_call_original

      create(:event_membership, parent_event: conference, child_event: livestream)

      expect(described_class).to have_received(:acquire_hierarchy_write_lock!).at_least(:once)
    end
  end

  describe "deletion safety and cache invalidation" do
    it "destroys only the membership links when a parent or child event is destroyed" do
      parent = create(:event, type_of: :conference)
      child = create(:event, type_of: :live_stream)
      membership = create(:event_membership, parent_event: parent, child_event: child)

      parent.destroy!

      expect(described_class.exists?(membership.id)).to be(false)
      expect(Event.exists?(child.id)).to be(true)
    end

    it "purges edge cache for both parent and child events when membership changes" do
      parent = create(:event, type_of: :conference, published: true)
      child = create(:event, type_of: :live_stream, published: true)
      allow(EdgeCache::PurgeByKeyWorker).to receive(:perform_async)

      membership = create(:event_membership, parent_event: parent, child_event: child)

      expect(EdgeCache::PurgeByKeyWorker)
        .to have_received(:perform_async).with(parent.record_key, array_including(parent.path))
      expect(EdgeCache::PurgeByKeyWorker)
        .to have_received(:perform_async).with(child.record_key, array_including(child.path))

      membership.destroy!
    end
  end
end
