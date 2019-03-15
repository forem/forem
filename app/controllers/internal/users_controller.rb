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
    update_role
    add_note
    @user.update!(user_params)
    if user_params[:quick_match]
      redirect_to "/internal/users/unmatched_mentee"
    else
      redirect_to "/internal/users/#{params[:id]}"
    end
  end

  def update_role
    toggle_ban_user if user_params[:ban_user]
    toggle_warn_user if user_params[:warn_user]
    toggle_trust_user if user_params[:trusted_user]
    toggle_pro_user if user_params[:pro_user]
    toggle_ban_from_mentorship if user_params[:ban_from_mentorship]
  end

  def toggle_ban_user
    if user_params[:ban_user] == "1"
      @user.add_role :banned
      @user.remove_role :trusted
      create_note("banned", user_params[:note_for_current_role])
    else
      @user.remove_role :banned
      create_note("good_standing", user_params[:note_for_current_role])
    end
  end

  def toggle_trust_user
    if user_params[:trusted_user] == "1"
      @user.add_role :trusted
    else
      @user.remove_role :trusted
    end
    Rails.cache.delete("user-#{@user.id}/has_trusted_role")
    @user.trusted
  end

  def toggle_pro_user
    if user_params[:pro_user] == "1"
      @user.add_role :pro
    else
      @user.remove_role :pro
    end
  end

  def toggle_warn_user
    if user_params[:warn_user] == "1"
      @user.add_role :warned
      @user.remove_role :trusted
      create_note("warned", user_params[:note_for_current_role])
    else
      @user.remove_role :warned
      create_note("good_standing", user_params[:note_for_current_role])
    end
  end

  def add_note
    return if user_params[:note].blank?

    create_note("misc_note", user_params[:note])
  end

  def create_note(reason, content)
    Note.create(
      author_id: current_user.id,
      noteable_id: @user.id,
      noteable_type: "User",
      reason: reason,
      content: content,
    )
  end

  def inactive_mentorship(mentor, mentee)
    relationship = MentorRelationship.where(mentor_id: mentor.id, mentee_id: mentee.id)
    relationship.update(active: false)
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

  def toggle_ban_from_mentorship
    if user_params[:ban_from_mentorship] == "1"
      @user.add_role :banned_from_mentorship
      mentee_relationships = MentorRelationship.where(mentor_id: @user.id)
      mentor_relationships = MentorRelationship.where(mentee_id: @user.id)
      deactivate_mentorship(mentee_relationships)
      deactivate_mentorship(mentor_relationships)
      @user.update(offering_mentorship: false, seeking_mentorship: false)
      create_note("banned_from_mentorship", user_params[:note_for_mentorship_ban])
    else
      @user.remove_role :banned_from_mentorship
    end
  end

  def deactivate_mentorship(relationships)
    relationships.each do |relationship|
      relationship.update(active: false)
    end
  end

  def banish
    @user = User.find(params[:id])
    begin
      Moderator::Banisher.call_banish(admin: current_user, offender: @user)
    rescue StandardError => e
      flash[:error] = e.message
    end
    redirect_to "/internal/users/#{@user.id}/edit"
  end

  def full_delete
    @user = User.find(params[:id])
    begin
      Moderator::Banisher.call_delete_activity(admin: current_user, offender: @user)
      flash[:notice] = "@" + @user.username + " (email: " + @user.email + ", user_id: " + @user.id.to_s + ") has been fully deleted. If this is a GDPR delete, remember to delete them from Mailchimp and Google Analytics."
    rescue StandardError => e
      flash[:error] = e.message
    end
    redirect_to "/internal/users"
  end

  private

  def user_params
    params.require(:user).permit(:seeking_mentorship,
                                :offering_mentorship,
                                :quick_match,
                                :note,
                                :add_mentor,
                                :add_mentee,
                                :ban_from_mentorship,
                                :ban_user,
                                :warn_user,
                                :note_for_mentorship_ban,
                                :note_for_current_role,
                                :reason_for_mentorship_ban,
                                :trusted_user,
                                :pro_user)
  end
end
