class Credit < ApplicationRecord
  attr_accessor :number_to_purchase

  belongs_to    :user, optional: true
  belongs_to    :organization, optional: true

  counter_culture :user,
                  column_name: proc { |model| "#{model.spent ? 'spent' : 'unspent'}_credits_count" },
                  column_names: {
                    ["credits.spent = ?", true] => "spent_credits_count",
                    ["credits.spent = ?", false] => "unspent_credits_count",
                    ["credits.id > ?", 0] => "credits_count"
                  }
  counter_culture :organization,
                  column_name: proc { |model| "#{model.spent ? 'spent' : 'unspent'}_credits_count" },
                  column_names: {
                    ["credits.spent = ?", true] => "spent_credits_count",
                    ["credits.spent = ?", false] => "unspent_credits_count",
                    ["credits.id > ?", 0] => "credits_count"
                  }

  def self.add_to(user, amount)
    credit_objects = []
    amount.times do
      credit_objects << Credit.new(user_id: user.id)
    end
    Credit.import credit_objects
  end

  def self.remove_from(user, amount)
    user.credits.where(spent: false).limit(amount).delete_all
  end

  def self.add_to_org(org, amount)
    credit_objects = []
    amount.times do
      credit_objects << Credit.new(organization_id: org.id)
    end
    Credit.import credit_objects
  end

  def self.remove_from_org(org, amount)
    org.credits.where(spent: false).limit(amount).delete_all
  end
end
