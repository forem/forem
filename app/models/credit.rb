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

  # Remove an :amount of credits from the given :user_or_org.
  #
  # @param user_or_org [#credits] the "owner" of the credits.
  # @param amount [Integer] the amount of credits to remove from the
  #        owner.
  #
  # @note If you specify removing more credits than the owner has, it
  #       will remove all of their credits but not create a negative
  #       balance.
  def self.remove_from(user_or_org, amount)
    user_or_org.credits.unspent.limit(amount).delete_all
    update_cache_columns(user_or_org)
  end

  # Update the given :user_or_org's cached information.
  #
  # @param user_or_org [#credits] the "owner" of the credits.
  def self.update_cache_columns(user_or_org)
    user_or_org.update(
      credits_count: user_or_org.credits.size,
      spent_credits_count: user_or_org.credits.spent.size,
      unspent_credits_count: user_or_org.credits.unspent.size,
    )
  end
end
