require "rails_helper"

RSpec.describe Events::SubEventSchedule do
  let(:now) { Time.zone.local(2026, 11, 25, 14, 0, 0) }
  let(:conference) do
    create(:event,
           type_of: :conference,
           published: true,
           start_time: now - 1.day,
           end_time: now + 2.days,
           data: { "time_zone" => "America/New_York" })
  end

  it "promotes live featured stream as hero and lists concurrent live sessions separately" do
    live_non_stream = create(:event, type_of: :challenge, published: true, primary_stream_url: nil,
                                     start_time: now - 2.hours, end_time: now + 5.hours)
    live_stream = create(:event, type_of: :live_stream, published: true,
                                 primary_stream_url: "https://youtube.com/watch?v=abcdefghijk",
                                 start_time: now - 30.minutes, end_time: now + 1.hour)
    featured_live = create(:event, type_of: :live_stream, published: true,
                                   primary_stream_url: "https://youtube.com/watch?v=zyxwvutsrqp",
                                   start_time: now - 15.minutes, end_time: now + 45.minutes)
    upcoming_stream = create(:event, type_of: :live_stream, published: true,
                                     start_time: now + 2.hours, end_time: now + 3.hours)
    past_stream = create(:event, type_of: :live_stream, published: true,
                                 start_time: now - 4.hours, end_time: now - 2.hours)

    create(:event_membership, parent_event: conference, child_event: live_non_stream, position: 0, role: "Hackathon")
    create(:event_membership, parent_event: conference, child_event: live_stream, position: 1, role: "Track B")
    featured_m = create(:event_membership, parent_event: conference, child_event: featured_live,
                                           position: 2, role: "Keynote", featured: true)
    create(:event_membership, parent_event: conference, child_event: upcoming_stream, position: 3, role: "Workshop")
    create(:event_membership, parent_event: conference, child_event: past_stream, position: 4, role: "Opening")

    schedule = described_class.new(conference, include_drafts: false, at: now)

    expect(schedule.hero_state).to eq(:live)
    expect(schedule.hero_membership).to eq(featured_m)
    expect(schedule.other_live_memberships.map(&:child_event)).to eq([live_stream, live_non_stream])
    expect(schedule.upcoming_memberships.map(&:child_event)).to eq([upcoming_stream])
    expect(schedule.past_memberships.map(&:child_event)).to eq([past_stream])
    expect(schedule.roles).to eq(["Hackathon", "Track B", "Keynote", "Workshop", "Opening"])
  end

  it "promotes soonest upcoming session as hero when nothing is live and groups upcoming by day" do
    later = create(:event, type_of: :live_stream, published: true,
                           start_time: now + 1.day + 3.hours, end_time: now + 1.day + 4.hours)
    soonest = create(:event, type_of: :live_stream, published: true,
                             start_time: now + 2.hours, end_time: now + 3.hours)
    draft_sooner = create(:event, type_of: :live_stream, published: false,
                                  start_time: now + 1.hour, end_time: now + 2.hours)

    create(:event_membership, parent_event: conference, child_event: later, position: 0)
    soonest_m = create(:event_membership, parent_event: conference, child_event: soonest, position: 1)
    draft_m = create(:event_membership, parent_event: conference, child_event: draft_sooner, position: 2)

    public_schedule = described_class.new(conference, include_drafts: false, at: now)
    expect(public_schedule.hero_state).to eq(:upcoming)
    expect(public_schedule.hero_membership).to eq(soonest_m)
    expect(public_schedule.total_count).to eq(2)
    expect(public_schedule.upcoming_by_day.keys.size).to eq(2)

    admin_schedule = described_class.new(conference, include_drafts: true, at: now)
    expect(admin_schedule.hero_membership).to eq(draft_m)
    expect(admin_schedule.total_count).to eq(3)
  end

  it "returns :past hero_state when all sub-events have ended" do
    ended = create(:event, type_of: :live_stream, published: true,
                           start_time: now - 5.hours, end_time: now - 3.hours)
    create(:event_membership, parent_event: conference, child_event: ended)

    schedule = described_class.new(conference, include_drafts: false, at: now)
    expect(schedule.hero_state).to eq(:past)
    expect(schedule.hero_membership).to be_nil
    expect(schedule.all_ended?).to be(true)
  end
end
