# frozen_string_literal: true

require 'time'
require 'bundler'
require 'get_process_mem'

require 'dead_end'

module DerailedBenchmarks
  def self.gem_is_bundled?(name)
    specs = ::Bundler.locked_gems.specs.each_with_object({}) {|spec, hash| hash[spec.name] = spec }
    specs[name]
  end

  class << self
    attr_accessor :auth
  end

  def self.rails_path_on_disk
    require 'rails/version'
    rails_version_file = Rails.method(:version).source_location[0]
    path = Pathname.new(rails_version_file).expand_path.parent.parent

    while path != Pathname.new("/")
      basename = path.expand_path.basename.to_s

      break if basename.start_with?("rails") && basename != "railties"
      path = path.parent
    end
    raise "Could not find rails folder on a folder in #{rails_version_file}"  if path == Pathname.new("/")
    path.expand_path
  end

  def self.add_auth(app)
    if use_auth = ENV['USE_AUTH']
      puts "Auth: #{use_auth}"
      auth.add_app(app)
    else
      app
    end
  end
end

require 'derailed_benchmarks/require_tree'
require 'derailed_benchmarks/auth_helper'

require 'derailed_benchmarks/stats_for_file'
require 'derailed_benchmarks/stats_from_dir'
require 'derailed_benchmarks/git/switch_project'

if DerailedBenchmarks.gem_is_bundled?("devise")
  DerailedBenchmarks.auth = DerailedBenchmarks::AuthHelpers::Devise.new
end
