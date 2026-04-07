class OnboardingChecklist < ApplicationRecord
  belongs_to :user

  ITEM_DEFINITIONS = [
    { key: "fill_out_profile", action_path: :user_settings_path },
    { key: "comment_in_welcome", action_path: :welcome_path },
    { key: "made_first_post", action_path: :new_path },
  ].freeze

  ITEM_KEYS = ITEM_DEFINITIONS.map { |d| d[:key] }.freeze

  # Called from callbacks when user completes an action
  def complete_item!(key)
    return unless key.in?(ITEM_KEYS)
    return if items[key]

    now = Time.current
    items[key] = now
    self.completed_at = now if all_completed?
    save!
  end

  def item_statuses
    ITEM_DEFINITIONS.map do |item|
      key = item[:key]
      {
        key:,
        label_i18n_key: "views.sidebars.onboarding_progress.items.#{key}",
        action_url: resolve_action_url(item),
        completed: !items[key].nil?,
      }
    end
  end

  def completed_count
    ITEM_KEYS.count { |k| items[k] }
  end

  def total_count
    ITEM_KEYS.size
  end

  def all_completed?
    ITEM_KEYS.all? { |k| items[k] }
  end

  def completed?
    !completed_at.nil?
  end

  private

  def resolve_action_url(item)
    routes = Rails.application.routes.url_helpers
    routes.public_send(item[:action_path])
  end
end
