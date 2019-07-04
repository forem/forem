class Credit < ApplicationRecord
  attr_accessor :number_to_purchase

  belongs_to :user, optional: true
  belongs_to :organization, optional: true
  belongs_to :purchase, polymorphic: true, optional: true

  scope :spent, -> { where(spent: true) }
  scope :unspent, -> { where(spent: false) }

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
    credit_objects = Array.new(amount) { Credit.new(user_id: user.id) }
    Credit.import credit_objects
    Credit.update_cache_columns(user)
  end

  def self.remove_from(user, amount)
    user.credits.where(spent: false).limit(amount).delete_all
    Credit.update_cache_columns(user)
  end

  def self.add_to_org(org, amount)
    credit_objects = Array.new(amount) { Credit.new(organization_id: org.id) }
    Credit.import credit_objects
    Credit.update_cache_columns(org)
  end

  def self.remove_from_org(org, amount)
    org.credits.where(spent: false).limit(amount).delete_all
    Credit.update_cache_columns(org)
  end

  def self.update_cache_columns(user_or_org)
    user_or_org.credits_count = user_or_org.credits.size
    user_or_org.spent_credits_count = user_or_org.credits.where(spent: true).size
    user_or_org.unspent_credits_count = user_or_org.credits.where(spent: false).size
    user_or_org.save
  end
end
