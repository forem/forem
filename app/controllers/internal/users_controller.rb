class Internal::UsersController < Internal::ApplicationController
  layout "internal"

  def index
    @users = case params[:state]
             when "mentors"
               User.where(offering_mentorship: true).page(params[:page]).per(50)
             when "mentees"
               User.where(seeking_mentorship: true).page(params[:page]).per(50)
             when /role\-/
               User.with_role(params[:state].split("-")[1], :any).page(params[:page]).per(50)
             else
               User.order("created_at DESC").page(params[:page]).per(50)
             end
    return unless params[:search].present?

    @users = @users.where('users.name ILIKE :search OR
      users.username ILIKE :search OR
      users.github_username ILIKE :search OR
      users.email ILIKE :search OR
      users.twitter_username ILIKE :search', search: "%#{params[:search].strip}%")
  end

  def edit
    @user = User.find(params[:id])
  end

  def show
    @user = if params[:id] == "unmatched_mentee"
              MentorRelationship.unmatched_mentees.order("RANDOM()").first
            else
              User.find(params[:id])
            end
    @user_mentee_relationships = MentorRelationship.where(mentor_id: @user.id)
    @user_mentor_relationships = MentorRelationship.where(mentee_id: @user.id)
  end

  def update
    @user = User.find(params[:id])
    @new_mentee = user_params[:add_mentee]
    @new_mentor = user_params[:add_mentor]
    make_matches
    add_note if user_params[:new_note]
    if user_params[:quick_match]
      redirect_to "/internal/users/unmatched_mentee"
    else
      redirect_to "/internal/users/#{params[:id]}"
    end
  end

  def add_note
    Note.create(
      author_id: current_user.id,
      noteable_id: @user.id,
      noteable_type: "User",
      reason: "misc_note",
      content: user_params[:new_note],
    )
  end

  def user_status
    @user = User.find(params[:id])
    begin
      Moderator::ManageActivityAndRoles.handle_user_roles(admin: current_user, user: @user, user_params: user_params)
      flash[:notice] = "User has been udated"
    rescue StandardError => e
      flash[:error] = e.message
    end
    redirect_to "/internal/users/#{@user.id}/edit"
  end

  def make_matches
    return if @new_mentee.blank? && @new_mentor.blank?

    if !@new_mentee.blank?
      mentee = User.find(@new_mentee)
      MentorRelationship.new(mentee_id: mentee.id, mentor_id: @user.id).save!
    end
    return unless !@new_mentor.blank?

    mentor = User.find(@new_mentor)
    MentorRelationship.new(mentee_id: @user.id, mentor_id: mentor.id).save!
  end

  def banish
    @user = User.find(params[:id])
    begin
      Moderator::BanishUser.call_banish(admin: current_user, user: @user)
    rescue StandardError => e
      flash[:error] = e.message
    end
    redirect_to "/internal/users/#{@user.id}/edit"
  end

  def full_delete
    @user = User.find(params[:id])
    begin
      Moderator::BanishUser.call_full_delete(admin: current_user, user: @user)
      flash[:notice] = "@" + @user.username + " (email: " + @user.email + ", user_id: " + @user.id.to_s + ") has been fully deleted. If this is a GDPR delete, remember to delete them from Mailchimp and Google Analytics."
    rescue StandardError => e
      flash[:error] = e.message
    end
    redirect_to "/internal/users"
  end

  def merge
    @user = User.find(params[:id])
    begin
      Moderator::MergeUser.call_merge(admin: current_user, keep_user: @user, delete_user_id: user_params["merge_user_id"])
    rescue StandardError => e
      flash[:error] = e.message
    end
    redirect_to "/internal/users/#{@user.id}/edit"
  end

  private

  def user_params
    params.require(:user).permit(:seeking_mentorship,
                            :offering_mentorship,
                            :quick_match,
                            :new_note,
                            :add_mentor,
                            :add_mentee,
                            :note_for_current_role,
                            :mentorship_note,
                            :user_status,
                            :toggle_mentorship,
                            :pro,
                            :merge_user_id)
  end
end
