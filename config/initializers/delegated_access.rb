require Rails.root.join("app/services/delegated_access/configuration")

Rails.application.config.x.delegated_access = DelegatedAccess::Configuration.from_env.freeze
