class AuthorizationService
  attr_accessor :auth, :signed_in_resource, :cta_variant

  def initialize(auth, signed_in_resource = nil, cta_variant = nil)
    @auth = auth
    @signed_in_resource = signed_in_resource
    @cta_variant = cta_variant
  end

  def get_user
    identity = build_identity
    return signed_in_resource if user_identity_exists(identity)

    user = proper_user(identity)
    user = if user.nil?
             build_user(identity)
           else
             update_user(user)
           end
    set_identity(identity, user)
    user.skip_confirmation!
    flag_spam_user(user) if account_less_than_a_week_old?(user, identity)
    user
  end

  def add_social_identity_data(user)
    return unless auth&.provider && auth&.extra && auth.extra.raw_info

    if auth.provider == "twitter"
      user.twitter_created_at = auth.extra.raw_info.created_at
      user.twitter_followers_count = auth.extra.raw_info.followers_count.to_i
      user.twitter_following_count = auth.extra.raw_info.friends_count.to_i
    else
      user.github_created_at = auth.extra.raw_info.created_at
    end
  end

  def build_identity
    identity = Identity.find_for_oauth(auth)
    identity.token = auth.credentials.token
    identity.secret = auth.credentials.secret
    auth["extra"].delete("access_token") if auth["extra"]["access_token"]
    identity.auth_data_dump = auth
    identity.save
    identity
  end

  def build_user(identity)
    user = User.where("#{identity.provider}_username" => auth.info.nickname).first
    if user.nil?
      user = User.new(
        name: auth.extra.raw_info.name,
        remote_profile_image_url: (auth.info.image || "").gsub("_normal", ""),
        github_username: (auth.info.nickname if auth.provider == "github"),
        signup_cta_variant: cta_variant,
        email: auth.info.email || "",
        twitter_username: (auth.info.nickname if auth.provider == "twitter"),
        password: Devise.friendly_token[0, 20],
      )
      user.name = auth.info.nickname if user.name.blank?
      user.skip_confirmation!
      user.set_remember_fields
      add_social_identity_data(user)
      user.saw_onboarding = false
      user.editor_version = "v2"
      user.onboarding_variant_version = %w[0 0 0 1 2 3 4 5 6 6 6 7 8 8 8 8 9].sample # 0, 6 and 8 promoted due to success
      user.save!
    end
    user
  end

  def update_user(user)
    user.set_remember_fields
    user.github_username = auth.info.nickname if auth.provider == "github" && auth.info.nickname != user.github_username
    user.twitter_username = auth.info.nickname if auth.provider == "twitter" && auth.info.nickname != user.twitter_username
    add_social_identity_data(user)
    user.profile_updated_at = Time.current if user.twitter_username_changed? || user.github_username_changed?
    user.save
    user
  end

  def proper_user(identity)
    if signed_in_resource
      signed_in_resource
    elsif identity.user
      identity.user
    elsif auth.info.email.present?
      User.find_by(email: auth.info.email)
    end
  end

  def set_identity(identity, user)
    return if identity.user_id.present?

    identity.user = user
    identity.save!
  end

  def user_identity_exists(identity)
    signed_in_resource &&
      Identity.where(provider: identity.provider, user_id: signed_in_resource.id).any?
  end

  def account_less_than_a_week_old?(user, logged_in_identity)
    user_identity_age = user.github_created_at ||
      user.twitter_created_at ||
      Time.zone.parse(logged_in_identity.auth_data_dump.extra.raw_info.created_at)
    # last one is a fallback in case both are nil
    range = 1.week.ago.beginning_of_day..Time.current
    range.cover?(user_identity_age)
  end

  def flag_spam_user(user)
    Slack::Messengers::PotentialSpammer.call(user: user)
  end
end
