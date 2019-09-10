# Be sure to restart your server when you modify this file.

Rails.application.config.session_store :redis_session_store, {
  key: "_PracticalDeveloper_session",
  redis: {
    expire_after: 2.weeks,  # cookie expiration
    ttl: 2.weeks,           # Redis expiration, defaults to 'expire_after'
    key_prefix: 'practicaldeveloper:session:',
    url: 'redis://localhost:6379/0',
  }
}
#, key: "_PracticalDeveloper_session"
