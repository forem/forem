require "yaml"

REACTION_CATEGORY_LIST = YAML.safe_load(Rails.root.join(*%w[config reactions.yml]).read)
