# Zeitwerk (Rails 6+) autoloader
# see https://guides.rubyonrails.org/autoloading_and_reloading_constants.html

# Configures default inflections for the zeitwerk autoloader
# see <https://guides.rubyonrails.org/autoloading_and_reloading_constants.html#customizing-inflections>
Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    "html_rouge" => "HTMLRouge",
    "url" => "URL",
  )
end

# Ignoring folders that don't adhere to the new naming conventions
Rails.autoloaders.main.ignore(Rails.root.join("lib/data_update_scripts"))
Rails.autoloaders.main.ignore(Rails.root.join("lib/generators/data_update"))
Rails.autoloaders.main.ignore(Rails.root.join("lib/generators/service"))
Rails.autoloaders.main.ignore(Rails.root.join("lib/generators/settings_model"))
