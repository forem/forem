# Forem apps AppIntegration are not meant to be modified by creators
class AppIntegrationPolicy < ApplicationPolicy
  def create?
    !@record.forem_app?
  end

  def edit?
    !@record.forem_app?
  end

  def update?
    !@record.forem_app?
  end

  def destroy?
    !@record.forem_app?
  end
end
