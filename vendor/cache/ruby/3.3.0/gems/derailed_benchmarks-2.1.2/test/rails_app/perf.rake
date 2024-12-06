# frozen_string_literal: true

$LOAD_PATH << File.expand_path("../../../lib", __FILE__)

require 'derailed_benchmarks'
require 'derailed_benchmarks/tasks'

if ENV['AUTH_CUSTOM_USER']
  DerailedBenchmarks.auth.user = -> { User.first_or_create!(email: "user@example.com", password: 'password') }
end
