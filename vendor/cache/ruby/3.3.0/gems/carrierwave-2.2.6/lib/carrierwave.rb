require 'fileutils'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/class/attribute'
require 'active_support/concern'

module CarrierWave

  class << self
    attr_accessor :root, :base_path
    attr_writer :tmp_path

    def configure(&block)
      CarrierWave::Uploader::Base.configure(&block)
    end

    def clean_cached_files!(seconds=60*60*24)
      CarrierWave::Uploader::Base.clean_cached_files!(seconds)
    end

    def tmp_path
      @tmp_path ||= File.expand_path(File.join('..', 'tmp'), root)
    end
  end

end

if defined?(Merb)

  CarrierWave.root = Merb.dir_for(:public)
  Merb::BootLoader.before_app_loads do
    # Setup path for uploaders and load all of them before classes are loaded
    Merb.push_path(:uploaders, Merb.root / 'app' / 'uploaders', '*.rb')
    Dir.glob(File.join(Merb.load_paths[:uploaders])).each {|f| require f }
  end

elsif defined?(Jets)

  module CarrierWave
    class Turbine < Jets::Turbine
      initializer "carrierwave.setup_paths" do |app|
        CarrierWave.root = Jets.root.to_s
        CarrierWave.tmp_path = "/tmp/carrierwave"
        CarrierWave.configure do |config|
          config.cache_dir = "/tmp/carrierwave/uploads/tmp"
        end
      end

      initializer "carrierwave.active_record" do
        ActiveSupport.on_load :active_record do
          require 'carrierwave/orm/activerecord'
        end
      end
    end
  end

elsif defined?(Rails)

  module CarrierWave
    class Railtie < Rails::Railtie
      initializer "carrierwave.setup_paths" do |app|
        CarrierWave.root = Rails.root.join(Rails.public_path).to_s
        CarrierWave.base_path = ENV['RAILS_RELATIVE_URL_ROOT']
        available_locales = Array(app.config.i18n.available_locales || [])
        if available_locales.blank? || available_locales.include?(:en)
          I18n.load_path.prepend(File.join(File.dirname(__FILE__), 'carrierwave', 'locale', "en.yml"))
        end
      end

      initializer "carrierwave.active_record" do
        ActiveSupport.on_load :active_record do
          require 'carrierwave/orm/activerecord'
        end
      end

      config.before_eager_load do
        CarrierWave::Storage::Fog.eager_load
      end
    end
  end

elsif defined?(Sinatra)
  if defined?(Padrino) && defined?(PADRINO_ROOT)
    CarrierWave.root = File.join(PADRINO_ROOT, "public")
  else

    CarrierWave.root = if Sinatra::Application.respond_to?(:public_folder)
      # Sinatra >= 1.3
      Sinatra::Application.public_folder
    else
      # Sinatra < 1.3
      Sinatra::Application.public
    end
  end
end

require "carrierwave/utilities"
require "carrierwave/error"
require "carrierwave/sanitized_file"
require "carrierwave/mounter"
require "carrierwave/mount"
require "carrierwave/processing"
require "carrierwave/version"
require "carrierwave/storage"
require "carrierwave/uploader"
require "carrierwave/compatibility/paperclip"
require "carrierwave/test/matchers"
