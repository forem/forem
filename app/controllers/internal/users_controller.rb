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
    @note = Note.find_by(noteable_id: @user.id, noteable_type: "User", reason: "mentorship")
    @user_mentees = MentorRelationship.where(mentor_id: @user.id)
    @user_mentors = MentorRelationship.where(mentee_id: @user.id)
  end

  def update
    @user = User.find(params[:id])

    mentorship_match
    add_note
    @user.update!(user_params)
    redirect_to "/internal/users/#{@user.id}"
  end

  def mentorship_match
    return if user_params[:add_mentee] == "" && user_params[:add_mentor] == ""
    if user_params[:add_mentee] && user_params[:add_mentor]
      MentorRelationship.new(mentee_id: User.find(user_params[:add_mentee]).id, mentor_id: @user.id).save
      MentorRelationship.new(mentee_id: @user.id, mentor_id: User.find(user_params[:add_mentor]).id).save
    elsif user_params[:add_mentor]
      MentorRelationship.new(mentee_id: @user.id, mentor_id: User.find(user_params[:add_mentor]).id).save
    elsif user_params[:add_mentee]
      MentorRelationship.new(mentee_id: User.find(user_params[:add_mentee]).id, mentor_id: @user.id).save
    end
  end

  def add_note
    if user_params[:mentorship_note]
      UserRoleService.new(@user).create_or_update_note("mentorship", user_params[:mentorship_note])
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
