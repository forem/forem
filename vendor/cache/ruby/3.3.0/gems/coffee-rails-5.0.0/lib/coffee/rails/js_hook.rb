module Coffee
  module Rails
    module JsHook
      extend ActiveSupport::Concern

      included do
        no_tasks do
          redefine_method :js_template do |source, destination|
            template(source + '.coffee', destination + '.coffee')
          end
        end
      end
    end
  end
end
