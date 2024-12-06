# encoding: utf-8

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.unshift(File.dirname(__FILE__))
require 'rspec'
require 'rails/all'
require 'js-routes'
require 'active_support/core_ext/hash/slice'

unless ENV['CI']
  code = system("yarn build")
  unless code
    exit(1)
  end
end


if defined?(JRUBY_VERSION)
  require 'rhino'
  JS_LIB_CLASS = Rhino
else
  require 'mini_racer'
  JS_LIB_CLASS = MiniRacer
end

def jscontext(force = false)
  if force
    @jscontext = JS_LIB_CLASS::Context.new
  else
    @jscontext ||= JS_LIB_CLASS::Context.new
  end
end

def js_error_class
  if defined?(JRUBY_VERSION)
    JS_LIB_CLASS::JSError
  else
    JS_LIB_CLASS::Error
  end
end

def evaljs(string, force: false, filename: 'context.js')
  jscontext(force).eval(string, filename: filename)
rescue MiniRacer::ParseError => e
  trace = e.message
  _, _, line, _ = trace.split(':')
  if line
    code = string.split("\n")[line.to_i-1]
    raise "#{trace}. Code: #{code.strip}";
  else
    raise e
  end
rescue MiniRacer::RuntimeError => e
  raise e
end

def evallib(**options)
  evaljs(JsRoutes.generate(**options), filename: 'lib/routes.js')
end

def test_routes
  ::App.routes.url_helpers
end

def blog_routes
  BlogEngine::Engine.routes.url_helpers
end

def planner_routes
  Planner::Engine.routes.url_helpers
end

def log(string)
  evaljs("console.log(#{string})")
end

def expectjs(string)
  expect(evaljs(string))
end

ActiveSupport::Inflector.inflections do |inflect|
  inflect.irregular "budgie", "budgies"
end


module Planner
  class Engine < Rails::Engine
    isolate_namespace Planner
  end
end

module BlogEngine
  class Engine < Rails::Engine
    isolate_namespace BlogEngine
  end

end


class ::App < Rails::Application
  config.paths['config/routes.rb'] << 'spec/config/routes.rb'
  config.root = File.expand_path('../dummy', __FILE__)
end


# prevent warning
Rails.configuration.active_support.deprecation = :log

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    draw_routes
  end

  config.before :each do
    log = proc do |*values|
      puts values.map(&:inspect).join(", ")
    end

    if defined?(JRUBY_VERSION)
      jscontext[:"console.log"] = lambda do |context, *values|
        log(*values)
      end
    else
      jscontext.attach("console.log", log)
    end
  end
end
