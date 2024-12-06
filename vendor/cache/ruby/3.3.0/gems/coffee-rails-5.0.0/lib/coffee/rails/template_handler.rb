module Coffee
  module Rails
    class TemplateHandler
      def self.erb_handler
        @@erb_handler ||= ActionView::Template.registered_template_handler(:erb)
      end

      def self.call(template, source = nil)
        compiled_source = if source
          erb_handler.call(template, source)
        else
          erb_handler.call(template)
        end
        "CoffeeScript.compile(begin;#{compiled_source};end)"
      end
    end
  end
end

ActiveSupport.on_load(:action_view) do
  ActionView::Template.register_template_handler :coffee, Coffee::Rails::TemplateHandler
  # Loads DependencyTracker
  require 'action_view/dependency_tracker'
  # Register ERB DependencyTracker for .coffee files to enable digesting.
  ActionView::DependencyTracker.register_tracker :coffee, ActionView::DependencyTracker::ERBTracker
end
