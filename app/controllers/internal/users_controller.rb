class Internal::UsersController < Internal::ApplicationController
  layout "internal"

  def index
    @users = case params[:state]
             when "mentors"
               User.where(offering_mentorship: true).page(params[:page]).per(20)
             when "mentees"
               User.where(seeking_mentorship: true).page(params[:page]).per(20)
             else
               User.order("created_at DESC").page(params[:page]).per(20)
             end
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
    ban_from_mentorship
    handle_mentorship
    warn_or_ban_user
    add_note
    @user.update!(user_params)
    if user_params[:quick_match]
      redirect_to "/internal/users/unmatched_mentee"
    else
      redirect_to "/internal/users/#{params[:id]}"
    end
  end

  def warn_or_ban_user
    if user_params[:ban_user] == "1"
      @user.add_role :banned
      create_note("banned", user_params[:note_for_current_role])
    elsif user_params[:warn_user] == "1"
      @user.add_role :warned
      create_note("warned", user_params[:note_for_current_role])
    elsif user_params[:good_standing_user] == "1"
      @user.remove_role :warned
      create_note("good_standing", user_params[:note_for_current_role])
    end
  end

  def add_note
    return unless !user_params[:note].blank?
    create_note("misc_note", user_params[:note])
  end

  def create_note(reason, content)
    Note.create(
      author_id: @current_user.id,
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

  def ban_from_mentorship
    return unless user_params[:ban_from_mentorship] == "1"
    @user.add_role :banned_from_mentorship
    mentee_relationships = MentorRelationship.where(mentor_id: @user.id)
    mentor_relationships = MentorRelationship.where(mentee_id: @user.id)
    deactivate_mentorship(mentee_relationships)
    deactivate_mentorship(mentor_relationships)
    create_note("banned_from_mentorship", user_params[:note_for_mentorship_ban])
  end

  def deactivate_mentorship(relationships)
    relationships.each do |relationship|
      relationship.update(active: false)
    end
  end

  def banish
    @user = User.find(params[:id])
    begin
      Moderator::Banisher.call(admin: current_user, offender: @user)
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
                                :note,
                                :ban_from_mentorship,
                                :ban_user,
                                :warn_user,
                                :good_standing_user, :note_for_mentorship_ban,
                                :note_for_current_role,
                                :reason_for_mentorship_ban)
  end
end
