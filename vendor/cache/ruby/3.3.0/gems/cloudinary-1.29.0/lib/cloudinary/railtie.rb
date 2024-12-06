class Cloudinary::Railtie < Rails::Railtie
  rake_tasks do
    Dir[File.join(File.dirname(__FILE__),'../tasks/**/*.rake')].each { |f| load f }
  end
  config.after_initialize do |app|
    ActiveSupport.on_load(:action_view) do
      ActionView::Base.send :include, CloudinaryHelper
    end
  end

  ActiveSupport.on_load(:action_controller_base) do
    ActionController::Base.send :include, Cloudinary::CloudinaryController
  end
end
