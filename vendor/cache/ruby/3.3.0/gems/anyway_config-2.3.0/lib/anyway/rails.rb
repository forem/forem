# frozen_string_literal: true

module Anyway
  module Rails
  end
end

require "anyway/rails/settings"
require "anyway/rails/config"
require "anyway/rails/loaders"

# Configure Rails loaders
Anyway.loaders.override :yml, Anyway::Rails::Loaders::YAML
Anyway.loaders.insert_after :yml, :secrets, Anyway::Rails::Loaders::Secrets
Anyway.loaders.insert_after :secrets, :credentials, Anyway::Rails::Loaders::Credentials

# Load Railties after configuring loaders.
# The application could be already initialized, and that would make `Anyway.loaders` frozen
require "anyway/railtie"
