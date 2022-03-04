module Credits
  class Manage
    def self.call(user, user_params)
      new(
        user,
        user_params.slice(:add_credits, :remove_credits),
        user_params.slice(:organization_id, :add_org_credits, :remove_org_credits),
      ).call
    end

    def initialize(user, user_params, org_params)
      @user = user
      @user_params = user_params
      @org_params = org_params
    end

    def call
      add_user_credits
      remove_user_credits
      add_org_credits
      remove_org_credits
    end

    private

    attr_reader :user, :user_params, :org_params

    def add_user_credits
      return unless user_params[:add_credits]

      amount = user_params[:add_credits].to_i
      Credit.add_to(user, amount)
    end

    def remove_user_credits
      return unless user_params[:remove_credits]

      amount = user_params[:remove_credits].to_i
      Credit.remove_from(user, amount)
    end

    def add_org_credits
      return unless org_params[:add_org_credits]

      amount = org_params[:add_org_credits].to_i
      Credit.add_to(organization, amount)
    end

    def remove_org_credits
      return unless org_params[:remove_org_credits]

      amount = org_params[:remove_org_credits].to_i
      Credit.remove_from(organization, amount)
    end

    def organization
      @organization ||= Organization.find(org_params[:organization_id])
    end
  end
end
