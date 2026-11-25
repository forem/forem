require "rails_helper"

RSpec.describe "Admin::EventMemberships and Hierarchical Admin Index" do
  let(:super_admin) { create(:user, :super_admin) }
  let(:regular_user) { create(:user) }
  let!(:conference) { create(:event, type_of: :conference, title: "Summit 2026", published: false) }
  let!(:stream_one) { create(:event, type_of: :live_stream, title: "Day 1 Keynote", published: false) }
  let!(:stream_two) { create(:event, type_of: :live_stream, title: "Day 2 Workshop", published: false) }

  describe "GET /admin/content_manager/events (hierarchical tree index)" do
    before { login_as(super_admin) }

    it "renders events hierarchically by default without duplicating sub-events at root level" do
      second_conf = create(:event, type_of: :conference, title: "Partner Conf", published: true)
      create(:event_membership, parent_event: conference, child_event: stream_one, role: "Keynote", featured: true)
      create(:event_membership, parent_event: second_conf, child_event: stream_one, role: "Cross-Stream")

      get admin_events_path
      expect(response).to have_http_status(:success)

      doc = Nokogiri::HTML(response.body)
      root_rows = doc.css('tr[data-depth="0"]')
      child_rows = doc.css('tr[data-depth="1"]')

      expect(root_rows.map(&:text).join).to include("Summit 2026", "Partner Conf", "Day 2 Workshop")
      expect(root_rows.map(&:text).join).not_to include("Day 1 Keynote")
      expect(child_rows.size).to eq(2)
      expect(response.body).to include("Shared in 2 parents")
    end

    it "supports flat view, search, type filter, and status filter" do
      create(:event_membership, parent_event: conference, child_event: stream_one)

      get admin_events_path(view: "flat")
      expect(response).to have_http_status(:success)
      doc = Nokogiri::HTML(response.body)
      expect(doc.css('tr[data-depth="0"]').size).to eq(3)

      get admin_events_path(q: "Keynote")
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Day 1 Keynote")
      expect(response.body).not_to include("Day 2 Workshop")
    end

    it "avoids N+1 queries across multiple parent conferences and sub-events" do
      3.times do |i|
        parent = create(:event, type_of: :conference, title: "Conf #{i}")
        2.times do |j|
          child = create(:event, type_of: :live_stream, title: "Stream #{i}-#{j}")
          create(:event_membership, parent_event: parent, child_event: child)
        end
      end

      queries = []
      callback = lambda { |_name, _start, _finish, _id, payload|
        sql = payload[:sql].to_s
        queries << sql unless payload[:name] == "SCHEMA" || sql.match?(/\A(BEGIN|COMMIT|SAVEPOINT|RELEASE)/)
      }

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        get admin_events_path
      end

      expect(response).to have_http_status(:success)
      membership_queries = queries.grep(/FROM "event_memberships"/)
      expect(membership_queries.size).to be <= 6
    end

    it "expands shared subtrees only once in the hierarchy tree to stay bounded on diamond DAGs" do
      second_conf = create(:event, type_of: :conference, title: "Second Conf")
      shared_track = create(:event, type_of: :other, title: "Shared Track")
      nested_leaf = create(:event, type_of: :live_stream, title: "Deep Leaf Session")

      create(:event_membership, parent_event: conference, child_event: shared_track)
      create(:event_membership, parent_event: second_conf, child_event: shared_track)
      create(:event_membership, parent_event: shared_track, child_event: nested_leaf)

      tree = Events::HierarchyTree.new
      all_nodes = []
      collect = lambda do |node|
        all_nodes << node
        node.children.each { |child| collect.call(child) }
      end
      tree.roots.each { |root| collect.call(root) }

      leaf_occurrences = all_nodes.select { |n| n.event.id == nested_leaf.id }
      collapsed_shared = all_nodes.select do |n|
        n.event.id == shared_track.id && n.collapsed_shared_children_count.positive?
      end

      expect(leaf_occurrences.size).to eq(1)
      expect(collapsed_shared.size).to eq(1)
    end
  end

  describe "managing memberships in admin" do
    before { login_as(super_admin) }

    it "attaches, updates, reorders, and detaches sub-events" do
      expect do
        post admin_event_memberships_path(conference),
             params: { event_membership: { child_event_id: stream_one.id, role: "Keynote", featured: true } }
      end.to change(EventMembership, :count).by(1)
      expect(response).to redirect_to(admin_event_path(conference, anchor: "event-hierarchy"))

      post admin_event_memberships_path(conference),
           params: { event_membership: { child_event_id: stream_two.id, role: "Workshop" } }

      first_m = EventMembership.find_by!(parent_event: conference, child_event: stream_one)
      second_m = EventMembership.find_by!(parent_event: conference, child_event: stream_two)

      patch admin_event_membership_path(conference, first_m),
            params: { event_membership: { role: "Opening Keynote", featured: false } }
      expect(first_m.reload).to have_attributes(role: "Opening Keynote", featured: false)

      patch reorder_admin_event_membership_path(conference, second_m, direction: "up")
      expect(conference.child_event_memberships.ordered.pluck(:child_event_id)).to eq([stream_two.id, stream_one.id])

      expect do
        delete admin_event_membership_path(conference, first_m)
      end.to change(EventMembership, :count).by(-1)
      expect(Event.exists?(stream_one.id)).to be(true)
    end

    it "creates a new sub-event pre-linked to a parent event via form" do
      get new_admin_event_path(parent_event_id: conference.id)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(conference.title)

      expect do
        post admin_events_path, params: {
          event: {
            title: "Attached Live Session",
            event_name_slug: conference.event_name_slug,
            event_variation_slug: "attached-live",
            type_of: "live_stream",
            start_time: 1.day.from_now,
            end_time: 1.day.from_now + 1.hour,
            published: false,
            parent_event_ids: ["", conference.id.to_s]
          }
        }
      end.to change(Event, :count).by(1).and change(EventMembership, :count).by(1)

      expect(conference.reload.sub_events.pluck(:title)).to include("Attached Live Session")
    end

    it "prevents unauthorized users from creating memberships" do
      login_as(regular_user)
      expect do
        post admin_event_memberships_path(conference),
             params: { event_membership: { child_event_id: stream_one.id } }
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end
end
