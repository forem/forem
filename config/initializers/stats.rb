# See: https://guides.rubyonrails.org/v7.0/autoloading_and_reloading_constants.html#use-case-1-during-boot-load-reloadable-code
Rails.application.config.to_prepare do
  ForemStatsClient = ForemStatsDriver.new # rubocop:disable Lint/ConstantDefinitionInBlock
end
