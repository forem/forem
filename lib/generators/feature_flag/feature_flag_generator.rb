class FeatureFlagGenerator < Rails::Generators::NamedBase
  REPLACEMENT_REGEX = /(def run).*?(end)/m

  def create_feature_flag_config
    append_file "config/feature_flags.yml", %(  - #{file_name}\n)
  end

  def create_dus
    script_name = "add_#{file_name}_feature_flag"
    generate "data_update", script_name, "--no-spec"
    file = Dir.glob("lib/data_update_scripts/*#{script_name}.rb").first
    raise "Can't find DataUpdateScript" unless file

    replacement = "\\1\n      FeatureFlag.add(:#{file_name})\n    \\2"
    gsub_file file, REPLACEMENT_REGEX, replacement
  end
end
