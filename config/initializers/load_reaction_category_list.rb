require "yaml"

Rails.configuration.after_initialize do
  ReactionCategory.list = YAML.safe_load(Rails.root.join(*%w[config reactions.yml]).read)
end
