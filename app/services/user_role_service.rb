class UserRoleService
  def initialize(user)
    @user = user
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
    users = user_ids.map { |id| User.find(id) }
    # Andy: Don't have to worry about comparing old and new values.
    tag.tag_moderator_ids.each do |id|
      User.find(id).remove_role(:tag_moderator, tag)
      puts "removed #{id}"
    end
    users.each do |user|
      user.add_role(:tag_moderator, tag)
      puts "added #{user.id}"
    end
    return true
  rescue ActiveRecord::RecordNotFound
    tag.errors[:moderator_ids] << ": user #{id} was not found"
    return false
  end

  private

  def new_roles?(params)
    params[:trusted] == "1" ? @user.add_role(:trusted) : @user.remove_role(:trusted)
    params[:analytics] == "1" ? @user.add_role(:analytics_beta_tester) : @user.remove_role(:analytics_beta_tester)
    if params[:scholar] == "1"
      @user.add_role(:workshop_pass)
      @user.update(workshop_expiration: params[:workshop_expiration])
      NotifyMailer.delay.scholarship_awarded_email(@user) if params[:scholar_email] == "1"
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

  def create_or_update_note(reason, content)
    note = Note.find_by(user_id: @user.id, reason: reason)
    if note.nil?
      Note.create(
        user_id: @user.id,
        reason: reason,
        content: content,
      )
    else
      note.update(content: content)
    end
  end

  def ban(content)
    @user.add_role :banned
    create_or_update_note("banned", content)
  end

  def unban
    @user.remove_role :banned
  end

  # Andy: Only give warning method b/c no need to remove warnings
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
