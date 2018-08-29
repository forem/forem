class Internal::UsersController < Internal::ApplicationController
  layout "internal"

  def index
    @users = case params[:state]
             when "mentors"
               User.where(offering_mentorship: true)
             when "mentees"
               User.where(seeking_mentorship: true)
             else
               User.
                 where(offering_mentorship: true).
                 or(User.where(seeking_mentorship: true))
             end
  end

  def edit
    @user = User.find(params[:id])
  end

  def show
    @user = User.find(params[:id])
    @user_mentees = MentorRelationship.where(mentor_id: @user.id)
    @user_mentors = MentorRelationship.where(mentee_id: @user.id)
  end

  def update
    @user = User.find(params[:id])
    mentorship_match
    add_note
    ban_from_mentorship
    @user.update!(user_params)
    redirect_to "/internal/users/#{@user.id}"
  end

  def mentorship_match
    binding.pry
    return if user_params[:add_mentee].blank? && user_params[:add_mentor].blank?

    if user_params[:add_mentor] && user_params[:add_mentee].blank?
      MentorRelationship.new(mentee_id: @user.id, mentor_id: User.find(user_params[:add_mentor]).id).save!
    elsif user_params[:add_mentee] && user_params[:add_mentor].blank?
      MentorRelationship.new(mentee_id: User.find(user_params[:add_mentee]).id, mentor_id: @user.id).save!
    else
      MentorRelationship.new(
        mentee_id: User.find(user_params[:add_mentee]).id,
        mentor_id: @user.id,
      ).save!
      MentorRelationship.new(
        mentee_id: @user.id,
        mentor_id: User.find(user_params[:add_mentor]).id,
      ).save!
    end
  rescue StandardError => e
    flash[:error] = e.message
  end

  def validates_mentor_relationship
    user_params[:add_mentee] != @user.id || user_params[:add_mentor] != @user.id && user_params[:add_mentee] != user_params[:add_mentor]
  end

  def add_note
    if user_params[:mentorship_note]
      Note.create(
        noteable_id: @user.id,
        noteable_type: "User",
        reason: "mentorship",
        content: user_params[:mentorship_note],
      )
    end
  end

  def inactive_mentorship(mentor, mentee)
    relationship = MentorRelationship.where(mentor_id: mentor.id, mentee_id: mentee.id)
    relationship.update(active: false)
  end

  def ban_from_mentorship
    if user_params[:banned_from_mentorship]
      @user.add_role :banned_from_mentorship
      mentee_relationships = MentorRelationship.where(mentor_id: @user.id)
      mentor_relationships = MentorRelationship.where(mentee_id: @user.id)
      deactivate_mentorship(mentee_relationships)
      deactivate_mentorship(mentor_relationships)

    end
  end

  def deactivate_mentorship(relationships)
    relationships.each do |relationship|
      relationship.update(active: false)
    end
  end

  def banish
    @user = User.find(params[:id])
    strip_user(@user)
    redirect_to "/internal/users/#{@user.id}/edit"
  end

  def strip_user(user)
    return unless user.comments.where("created_at < ?", 7.days.ago).empty?
    new_name = "spam_#{rand(10000)}"
    new_username = "spam_#{rand(10000)}"
    if User.find_by(name: new_name) || User.find_by(username: new_username)
      new_name = "spam_#{rand(10000)}"
      new_username = "spam_#{rand(10000)}"
    end
    user.name = new_name
    user.username = new_username
    user.twitter_username = ""
    user.github_username = ""
    user.website_url = ""
    user.summary = ""
    user.location = ""
    user.education = ""
    user.employer_name = ""
    user.employer_url = ""
    user.employment_title = ""
    user.mostly_work_with = ""
    user.currently_learning = ""
    user.currently_hacking_on = ""
    user.available_for = ""
    user.email_public = false
    user.add_role :banned
    unless user.notes.where(reason: "banned").any?
      user.notes.create!(reason: "banned", content: "spam account")
    end
    user.comments.each do |comment|
      comment.reactions.each &:destroy!
      comment.destroy!
    end
    user.articles.each &:destroy!
    user.remove_from_index!
    user.save!
    user.update!(old_username: nil)
  rescue StandardError => e
    flash[:error] = e.message
  end

  private

  def user_params
    params.require(:user).permit(:seeking_mentorship,
                                 :offering_mentorship,
                                 :add_mentor,
                                 :add_mentee,
                                 :mentorship_note,
                                 :change_mentorship_status,
                                 :banned_from_mentorship)
  end
end
