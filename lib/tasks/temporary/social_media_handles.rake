namespace :temporary do
  namespace :social_media do
    desc "Update DEV's social media handles"
    task update_handles: :environment do
      SiteConfig.public_send("social_media_handles=", twitter: "thepracticaldev", facebook: "thepracticaldev", github: "thepracticaldev", instagram: "thepracticaldev", twitch: "thepracticaldev")
    end
  end
end
