class AuthorizationService
  attr_accessor :auth, :signed_in_resource, :cta_variant
  def initialize(auth, signed_in_resource = nil, cta_variant=nil)
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
    user
  end

  def add_social_identity_data(user)
    return unless auth && auth.provider && auth.extra && auth.extra.raw_info
    if auth.provider == "twitter"
      user.twitter_created_at = auth.extra.raw_info.created_at
      user.twitter_followers_count = auth.extra.raw_info.followers_count.to_i
      user.twitter_following_count = auth.extra.raw_info.friends_count.to_i
    else
      user.github_created_at = auth.extra.raw_info.created_at
    end
  end

  def see_onboarding?
    !cta_variant.nil? &&
      (cta_variant == "navbar_basic" ||
        cta_variant&.include?("notifications") ||
        cta_variant&.include?("welcome-widget") ||
        cta_variant&.include?("in-feed-cta"))
  end

  def build_identity
    identity = Identity.find_for_oauth(auth)
    identity.token = auth.credentials.token
    identity.secret = auth.credentials.secret
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
      if user.name.blank?
        user.name = auth.info.nickname
      end
      user.skip_confirmation!
      user.remember_me!
      user.remember_me = true
      add_social_identity_data(user)
      user.saw_onboarding = !see_onboarding?
      user.save!
    end
    user
  end

  def update_user(user)
    if auth.provider == "github" && auth.info.nickname != user.github_username
      user.github_username = auth.info.nickname
    end
    if auth.provider == "twitter" && auth.info.nickname != user.twitter_username
      user.twitter_username = auth.info.nickname
    end
    user.remember_me!
    user.remember_me = true
    add_social_identity_data(user)
    user.save
    user
  end

  def proper_user(identity)
    if signed_in_resource
      signed_in_resource
    elsif identity.user
      identity.user
    elsif !auth.info.email.blank?
      User.find_by_email(auth.info.email)
    end
  end

  def set_identity(identity, user)
    if identity.user_id.blank?
      identity.user = user
      identity.save!
    end
  end

  def user_identity_exists(identity)
    signed_in_resource &&
      Identity.where(provider: identity.provider, user_id: signed_in_resource.id).any?
  end
end
