Rails.application.reloader.to_prepare do
  ForemStatsClient = ForemStatsDriver.new # rubocop:disable Lint/ConstantDefinitionInBlock
end
