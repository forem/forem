require "rails_helper"

RSpec.describe "internal/users", type: :request do
  let(:mentor) { create(:user) }
  let(:mentee) { create(:user) }
  let(:admin)  { create(:user, :super_admin) }

  before do
    login_as(admin)
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

  describe "GETS /internal/users/:id" do
    it "renders to appropriate page" do
      get "/internal/users/#{mentor.id}"
      expect(response.body).to include(mentor.username)
    end
  end

  describe "PUT internal/users/:id" do
    it "updates user to offer mentorship" do
      put "/internal/users/#{mentor.id}",
      params: { user: { offering_mentorship: true } }
      expect(mentor.reload.offering_mentorship).to eq(true)
    end

    it "updates user to seek mentorship" do
      put "/internal/users/#{mentee.id}", params: { user: { seeking_mentorship: true } }
      expect(mentee.reload.seeking_mentorship).to eq(true)
    end

    it "bans user from mentorship" do
      put "/internal/users/#{mentor.id}", params: { user: { banned_from_mentorship: true } }
      expect(mentor.reload.banned_from_mentorship).to eq(true)

    end

    it "pairs mentor with a mentee" do
      put "/internal/users/#{mentor.id}", params: { user: { add_mentee: mentee.id } }
      expect(mentee.mentors[0].id).to eq(mentor.id)
    end

    it "pairs mentee with a mentor" do
      put "/internal/users/#{mentee.id}", params: { user: {add_mentor: mentor.id} }
      expect(mentor.mentees[0].id).to eq(mentee.id)
    end

  end

end