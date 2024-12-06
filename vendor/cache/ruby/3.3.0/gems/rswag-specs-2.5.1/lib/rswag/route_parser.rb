# frozen_string_literal: true

module Rswag
  class RouteParser
    attr_reader :controller

    def initialize(controller)
      @controller = controller
    end

    def routes
      ::Rails.application.routes.routes.select do |route|
        route.defaults[:controller] == controller
      end.each_with_object({}) do |route, tree|
        path = path_from(route)
        verb = verb_from(route)
        tree[path] ||= { params: params_from(route), actions: {} }
        tree[path][:actions][verb] = { summary: summary_from(route) }
        tree
      end
    end

    private

    def path_from(route)
      route.path.spec.to_s
        .chomp('(.:format)') # Ignore any format suffix
        .gsub(/:([^\/.?]+)/, '{\1}') # Convert :id to {id}
    end

    def verb_from(route)
      verb = route.verb
      if verb.is_a? String
        verb.downcase
      else
        verb.source.gsub(/[$^]/, '').downcase
      end
    end

    def summary_from(route)
      verb = route.requirements[:action]
      noun = route.requirements[:controller].split('/').last.singularize

      # Apply a few customizations to make things more readable
      case verb
      when 'index'
        verb = 'list'
        noun = noun.pluralize
      when 'destroy'
        verb = 'delete'
      end

      "#{verb} #{noun}"
    end

    def params_from(route)
      route.segments - ['format']
    end
  end
end
