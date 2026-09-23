# Built from the environment inside to_prepare so the autoloaded
# DelegatedAccess constants are resolved by Zeitwerk rather than required by
# hand. The configuration is frozen; in development it is simply rebuilt on
# code reload.
Rails.application.config.to_prepare do
  Rails.application.config.x.delegated_access = DelegatedAccess::Configuration.from_env.freeze
end
