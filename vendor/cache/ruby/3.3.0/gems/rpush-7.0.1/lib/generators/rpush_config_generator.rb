class RpushConfigGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  def copy_config
    copy_file 'rpush.rb', $RPUSH_CONFIG_PATH
  end
end
