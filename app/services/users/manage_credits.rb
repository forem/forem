module Users
  class ManageCredits
    def self.call(*args)
      new(*args).call
    end

    def initialize(user, user_params)
      @user = user
      @organization_id = user_params[:organization_id]
      @add_credits_param = user_params[:add_credits]
      @remove_credits_param = user_params[:remove_credits]
      @add_org_credits_param = user_params[:add_org_credits]
      @remove_org_credits_param = user_params[:remove_org_credits]
    end

    def call
      add_credits if add_credits_param
      remove_credits if remove_credits_param
      add_org_credits if add_org_credits_param
      remove_org_credits if remove_org_credits_param
    end

    private

    attr_reader :user, :add_credits_param, :add_org_credits_param, :remove_org_credits_param,
                :remove_credits_param, :organization_id

    def add_credits
      amount = add_credits_param.to_i
      Credit.add_to(user, amount)
    end

    def remove_credits
      amount = remove_credits_param.to_i
      Credit.remove_from(user, amount)
    end

    def add_org_credits
      org = Organization.find(organization_id)
      amount = add_org_credits_param.to_i
      Credit.add_to(org, amount)
    end

    def remove_org_credits
      org = Organization.find(organization_id)
      amount = remove_org_credits_param.to_i
      Credit.remove_from(org, amount)
    end
  end
end
