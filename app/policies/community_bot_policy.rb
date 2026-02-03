class CommunityBotPolicy < ApplicationPolicy
  def index?
    has_mod_permission?
  end

  def new?
    has_mod_permission?
  end

  def create?
    has_mod_permission?
  end

  def show?
    has_mod_permission?
  end

  def destroy?
    has_mod_permission?
  end

  private

  def has_mod_permission?
    return true if user.any_admin?
    return true if user.super_moderator?
    
    # If record is a User (bot), check if user is moderator for that bot's subforem
    if record.is_a?(User) && record.community_bot?
      return true if user.subforem_moderator?(subforem: Subforem.find(record.onboarding_subforem_id))
    end
    
    # If record is a Subforem, check if user is moderator for that subforem
    if record.is_a?(Subforem)
      return true if user.subforem_moderator?(subforem: record)
    end

    false
  end
end
