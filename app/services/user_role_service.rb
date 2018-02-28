class UserRoleService
  def initialize(user)
    @user = user
    @bannable = nil
    @warnable = nil
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
      @bannable = false
    elsif params[:banned] == "1" && params[:reason_for_ban].blank?
      @user.errors[:reason_for_ban] << "can't be blank if banned is checked"
      @bannable = false
    elsif params[:banned] == "1"
      ban(params[:reason_for_ban])
      @bannable = true
    else
      unban
      @bannable = true
    end
  end

  def warnable?(params)
    if params[:warned] == "0" && !params[:reason_for_warning].blank?
      @user.errors[:warned] << "was not checked but had the reason filled out"
      @warnable = false
    elsif params[:warned] == "1" && params[:reason_for_warning].blank?
      @user.errors[:reason_for_warning] << "can't be blank if warned is checked"
      @warnable = false
    elsif params[:warned] == "1"
      give_warning(params[:reason_for_warning])
      @warnable = true
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

  def give_warning(content)
    @user.add_role :warned
    create_or_update_note("warned", content)
  end

  # Andy: no need to remove a warning from a user
end
