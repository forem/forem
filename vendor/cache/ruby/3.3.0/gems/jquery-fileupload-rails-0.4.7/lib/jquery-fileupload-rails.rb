module JQuery
  module FileUpload
    module Rails
      require 'jquery/fileupload/rails/engine' if defined?(Rails)
    end
  end
end
require 'jquery/fileupload/rails/upload' if defined?(Rails)
