# encoding: utf-8
require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'bundler/gem_tasks'
require 'rspec/core'
require 'rspec/core/rake_task'
require 'appraisal'
require 'rails/version'
if Rails.version < "6.1"
  load "rails/tasks/routes.rake"
end

RSpec::Core::RakeTask.new(:spec)

task :test_all => :appraisal # test all rails

task :default => :spec


namespace :spec do
  desc "Print all routes defined in test env"
  task :routes do
    require './spec/spec_helper'
    require 'action_dispatch/routing/inspector'
    draw_routes
    all_routes = Rails.application.routes.routes
    inspector = ActionDispatch::Routing::RoutesInspector.new(all_routes)
    puts inspector.format(ActionDispatch::Routing::ConsoleFormatter::Sheet.new)
  end
end
