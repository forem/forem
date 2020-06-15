class Credit < ApplicationRecord
  attr_accessor :number_to_purchase

  belongs_to :user, optional: true
  belongs_to :organization, optional: true
  belongs_to :purchase, polymorphic: true, optional: true

  scope :spent, -> { where(spent: true) }
  scope :unspent, -> { where(spent: false) }

  %i[user organization].each do |type|
    counter_culture type,
                    column_name: ->(model) { "#{model.spent ? 'spent' : 'unspent'}_credits_count" },
                    column_names: {
                      ["credits.spent = ?", true] => "spent_credits_count",
                      ["credits.spent = ?", false] => "unspent_credits_count",
                      ["credits.id > ?", 0] => "credits_count"
                    }
  end

  def self.add_to(user_or_org, amount)
    return unless amount.positive?

    now = Time.current
    association_id = "#{user_or_org.class.name.underscore}_id"
    attributes = Array.new(amount) do
      {
        association_id => user_or_org.id,
        :created_at => now,
        :updated_at => now
      }
    end

    insert_all(attributes)

    update_cache_columns(user_or_org)
  end

  def self.remove_from(user_or_org, amount)
    user_or_org.credits.where(spent: false).limit(amount).delete_all
    update_cache_columns(user_or_org)
  end

  def self.update_cache_columns(user_or_org)
    user_or_org.update(
      credits_count: user_or_org.credits.size,
      spent_credits_count: user_or_org.credits.where(spent: true).size,
      unspent_credits_count: user_or_org.credits.where(spent: false).size,
    )
  end
end
