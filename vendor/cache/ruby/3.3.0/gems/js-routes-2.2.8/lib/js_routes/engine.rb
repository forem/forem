module JsRoutes
class SprocketsExtension
  def initialize(filename, &block)
    @filename = filename
    @source   = block.call
  end

  def render(context, empty_hash_wtf)
    self.class.run(@filename, @source, context)
  end

  def self.run(filename, source, context)
    if context.logical_path == 'js-routes'
      routes = Rails.root.join('config', 'routes.rb').to_s
      context.depend_on(routes)
    end
    source
  end

  def self.call(input)
    filename = input[:filename]
    source   = input[:data]
    context  = input[:environment].context_class.new(input)

    result = run(filename, source, context)
    context.metadata.merge(data: result)
  end
end


class Engine < ::Rails::Engine
  def self.install_sprockets!
    return if defined?(@installed_sprockets)
    require 'sprockets/version'
    v2                = Gem::Dependency.new('', ' ~> 2')
    vgte3             = Gem::Dependency.new('', ' >= 3')
    sprockets_version = Gem::Version.new(::Sprockets::VERSION).release
    initializer_args  = case sprockets_version
                          when -> (v) { v2.match?('', v) }
                            { after: "sprockets.environment" }
                          when -> (v) { vgte3.match?('', v) }
                            { after: :engines_blank_point, before: :finisher_hook }
                          else
                            raise StandardError, "Sprockets version #{sprockets_version} is not supported"
                        end

    initializer 'js-routes.dependent_on_routes', initializer_args do
      case sprockets_version
        when  -> (v) { v2.match?('', v) },
              -> (v) { vgte3.match?('', v) }

        Rails.application.config.assets.configure do |config|
          config.register_preprocessor(
            "application/javascript",
            SprocketsExtension,
          )
        end
      else
        raise StandardError, "Sprockets version #{sprockets_version} is not supported"
      end
    end
    @installed_sprockets = true
  end
  if defined?(::Sprockets::Railtie)
    install_sprockets!
  end
end
end
