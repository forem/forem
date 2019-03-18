class Dashboard
  attr_reader :user_or_org

  def initialize(user_or_org)
    @user_or_org = user_or_org
  end
end
