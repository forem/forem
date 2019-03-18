require "rails_helper"

RSpec.describe "internal/users", type: :request do
  let(:mentor) { create(:user) }
  let(:mentee) { create(:user) }
  let(:admin)  { create(:user, :super_admin) }

  before do
    sign_in(admin)
    mentor
    mentee
  end

  describe "GETS /internal/users" do
    it "renders to appropriate page" do
      get "/internal/users"
      expect(response.body).to include(mentor.username)
    end

    it "only displays mentors on ?state=mentors" do
      get "/internal/users?state=mentors"
      expect(response.body).not_to include(mentee.username)
    end

    it "only displays mentees on ?state=mentees" do
      get "/internal/users?state=mentees"
      expect(response.body).not_to include(mentor.username)
    end
  end

  describe "GET /internal/users/:id" do
    it "renders to appropriate page" do
      get "/internal/users/#{mentor.id}"
      expect(response.body).to include(mentor.username)
    end
  end

  describe "PUT internal/users/:id" do
    it "pairs mentor with a mentee" do
      put "/internal/users/#{mentor.id}", params: { user: { add_mentee: mentee.id } }
      expect(mentee.mentors[0].id).to eq(mentor.id)
    end

    it "pairs mentee with a mentor" do
      put "/internal/users/#{mentee.id}", params: { user: { add_mentor: mentor.id } }
      expect(mentor.mentees[0].id).to eq(mentee.id)
    end

    it "deactivates existing mentorships when user is banned" do
      put "/internal/users/#{mentor.id}", params: { user: { add_mentee: mentee.id } }
      patch "/internal/users/#{mentor.id}/user_status", params: { user: { toggle_mentorship: "1", mentorship_note: "banned from mentorship" } }
      expect(MentorRelationship.where(mentor_id: mentor.id)[0].active).to eq(false)
      expect(mentor.notes[0].reason).to eq("banned_from_mentorship")
    end
  end

  describe "GET internal/users/:id/edit" do
    it "redirects from /username/moderate" do
      get "/#{mentor.username}/moderate"
      expect(response).to redirect_to("/internal/users/#{mentor.id}")
    end

    it "shows banish button for new users" do
      get "/internal/users/#{mentor.id}/edit"
      expect(response.body).to include("Banish User for Spam!")
    end

    it "does not show banish button for non-admins" do
      sign_out(admin)
      expect { get "/internal/users/#{mentor.id}/edit" }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  describe "PUT internal/users/:id/edit" do
    it "bans user for spam" do
      post "/internal/users/#{mentor.id}/banish"
      expect(mentor.reload.username).to include("spam")
    end
  end
end
