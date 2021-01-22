return if Rails.env.production?

require Rails.root.join("app/models/site_config")

SiteConfig.waiting_on_first_user = true # The intial admin has been created
SiteConfig.public = false
