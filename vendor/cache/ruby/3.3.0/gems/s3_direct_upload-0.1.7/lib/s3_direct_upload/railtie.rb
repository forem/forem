module S3DirectUpload
  class Railtie < Rails::Railtie
    initializer "railtie.configure_rails_initialization" do |app|
      app.middleware.use JQuery::FileUpload::Rails::Middleware
    end
  end
end