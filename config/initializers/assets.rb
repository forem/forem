# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Yarn node_moduless
Rails.application.config.assets.paths << Rails.root.join("node_modules")

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )
Rails.application.config.assets.precompile += %w[favicon.ico]
# Add client/assets/ folders to asset pipeline's search path.
# If you do not want to move existing images and fonts from your Rails app
# you could also consider creating symlinks there that point to the original
# rails directories. In that case, you would not add these paths here.
# Rails.application.config.assets.paths << Rails.root.join("client", "assets", "stylesheets")
# Rails.application.config.assets.paths << Rails.root.join("client", "assets", "images")
# Rails.application.config.assets.paths << Rails.root.join("client", "assets", "fonts")
# Rails.application.config.assets.precompile += %w( generated/server-bundle.js )

Rails.application.config.assets.precompile += %w[minimal.css]
Rails.application.config.assets.precompile += %w[s3_direct_upload.css]
Rails.application.config.assets.precompile += %w[base.js]
Rails.application.config.assets.precompile += %w[hello-dev.js]
Rails.application.config.assets.precompile += %w[s3_direct_upload.js]
Rails.application.config.assets.precompile += %w[classified_listings.css]
Rails.application.config.assets.precompile += %w[lib/xss.js]
Rails.application.config.assets.precompile += %w[lib/pulltorefresh.js]
Rails.application.config.assets.precompile += %w[internal.js]
Rails.application.config.assets.precompile += %w[serviceworker.js manifest.json]
