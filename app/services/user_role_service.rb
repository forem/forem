class UserRoleService
  def initialize(user, current_user_id)
    @user = user
    @current_user_id = current_user_id
  end

  def check_for_roles(params)
    if @user.banned && params[:banned] == "0"
      unban
    else
      bannable?(params)
      warnable?(params)
    end
    new_roles?(params)
  end

  def update_tag_moderators(user_ids, tag)
    users = user_ids.map do |id|
      User.find(id)
    rescue ActiveRecord::RecordNotFound # rubocop:disable Layout/RescueEnsureAlignment
      tag.errors[:moderator_ids] << ": user id #{id} was not found"
    end
    return false if tag.errors[:moderator_ids].present?

    # Don't have to worry about comparing old and new values.
    tag.tag_moderator_ids.each do |id|
      User.find(id).remove_role(:tag_moderator, tag)
    end
    users.find_each do |user|
      user.add_role(:tag_moderator, tag)
    end
    true
  end

  def create_or_update_note(reason, content)
    note = Note.find_by(noteable_id: @user.id, noteable_type: "User", reason: reason)
    if note.present?
      note.update(content: content)
    else
      Note.create(
        author_id: @current_user_id,
        noteable_id: @user.id,
        noteable_type: "User",
        reason: reason,
        content: content,
      )
    end
  end

  private

  def new_roles?(params)
    params[:trusted] == "1" ? @user.add_role(:trusted) : @user.remove_role(:trusted)
    if params[:analytics] == "1"
      @user.add_role(:analytics_beta_tester)
    else
      @user.remove_role(:analytics_beta_tester)
    end
    if params[:scholar] == "1"
      @user.add_role(:workshop_pass)
      @user.update(workshop_expiration: params[:workshop_expiration])
      ScholarshipMailer.delay.scholarship_awarded_email(@user) if params[:scholar_email] == "1"
    else
      @user.remove_role(:workshop_pass)
    end
  end

  def bannable?(params)
    if params[:banned] == "0" && !params[:reason_for_ban].blank?
      @user.errors[:banned] << "was not checked but had the reason filled out"
    elsif params[:banned] == "1" && params[:reason_for_ban].blank?
      @user.errors[:reason_for_ban] << "can't be blank if banned is checked"
    elsif params[:banned] == "1"
      ban(params[:reason_for_ban])
    else
      unban
    end
  end

  def warnable?(params)
    if params[:warned] == "0" && !params[:reason_for_warning].blank?
      @user.errors[:warned] << "was not checked but had the reason filled out"
    elsif params[:warned] == "1" && params[:reason_for_warning].blank?
      @user.errors[:reason_for_warning] << "can't be blank if warned is checked"
    elsif params[:warned] == "1"
      give_warning(params[:reason_for_warning])
    end
  end

  def ban(content)
    @user.add_role :banned
    create_or_update_note("banned", content)
  end

  def unban
    @user.remove_role :banned
  end

  # Only give warning method b/c no need to remove warnings
  def give_warning(content)
    @user.add_role :warned
    create_or_update_note("warned", content)
  end

  def validate_user_ids(user_ids)
    user_ids.each do |id|
      User.find(id)
    end
  end
end
