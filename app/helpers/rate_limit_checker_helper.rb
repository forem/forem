module RateLimitCheckerHelper
  NEW_USER_MESSAGE = "How many %<thing>s can a new member (%<timeframe>s or less) " \
    "create within any 5 minute period?".freeze

  def self.new_user_message(thing)
    timeframe = "day".pluralize(SiteConfig.user_considered_new_days)
    format(NEW_USER_MESSAGE, thing: thing, timeframe: timeframe)
  end

  CONFIGURABLE_RATES = {
    published_article_creation: {
      min: 0,
      placeholder: 9,
      title: "Limit number of posts created",
      description: "How many posts can someone create within any 30 second period?"
    },
    published_article_antispam_creation: {
      min: 0,
      placeholder: 1,
      title: "Limit number of posts created by a new member",
      description: new_user_message("posts")
    },
    article_update: {
      min: 1,
      placeholder: 30,
      title: "Limit number of updates to a post",
      description: "How many updates can someone make within any 30 second period? Update API docs when changed."
    },
    image_upload: {
      min: 0,
      placeholder: 9,
      title: "Limit number of images uploaded",
      description: "How many images can someone upload within any 30 second period?"
    },
    user_update: {
      min: 1,
      placeholder: 5,
      title: "Limit number of changes someone can make to their account",
      description: "How many changes can someone make to their user account within any 30 second period?"
    },
    follow_count_daily: {
      min: 0,
      placeholder: 500,
      title: "Limit number of followers someone can follow daily",
      description: "How many people can someone follow in a day?"
    },
    reaction_creation: {
      min: 1,
      placeholder: 10,
      title: "Limit number of reactions to a post or comment",
      description: "How many times can someone react to a post or comment within any 30 second period?"
    },
    feedback_message_creation: {
      min: 1,
      placeholder: 5,
      title: "Limit number of times someone can report abuse",
      description: "How many times can someone report abuse within any 5 minute period?"
    },
    comment_creation: {
      min: 0,
      placeholder: 9,
      title: "Limit number of comments created",
      description: "How many comments can someone create within any 30 second period?"
    },
    comment_antispam_creation: {
      min: 0,
      placeholder: 1,
      title: "Limit number of comments created by a new member",
      description: new_user_message("comments")
    },
    mention_creation: {
      min: 0,
      placeholder: 7,
      title: "Limit number of @-mentions in a post or comment",
      description: "How many times can someone @-mention other users in a post or comment?"
    },
    listing_creation: {
      min: 1,
      placeholder: 1,
      title: "Limit number of listings created",
      description: "How many listings can someone create within any 1 minute period?"
    },
    organization_creation: {
      min: 1,
      placeholder: 1,
      title: "Limit number of organizations created",
      description: "How many organizations can someone create within any 5 minute period?"
    },
    user_subscription_creation: {
      min: 0,
      placeholder: 3,
      title: "Limit number of times someone can subscribe to mailing list liquid tag",
      description: "How many times can someone subscribe to a mailing list within any 30 second period?"
    },
    email_recipient: {
      min: 0,
      placeholder: 5,
      title: "Limit number of general emails we send",
      description: "How many emails can we send to someone within any 2 minute period?"
    },
    send_email_confirmation: {
      min: 1,
      placeholder: 2,
      title: "Limit number of confirmation emails we send",
      description: "How many times can we send a confirmation email to someone within a 2 minute period?"
    }
  }.freeze

  def configurable_rate_limits
    CONFIGURABLE_RATES
  end
end
