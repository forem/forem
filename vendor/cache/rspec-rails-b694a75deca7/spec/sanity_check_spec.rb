require 'pathname'

RSpec.describe "Verify required rspec dependencies" do

  tmp_root = Pathname.new(RSpec::Core::RubyProject.root).join("tmp")

  before { FileUtils.mkdir_p tmp_root }

  def with_clean_env
    if Bundler.respond_to?(:with_unbundled_env)
      Bundler.with_unbundled_env { yield }
    else
      Bundler.with_clean_env { yield }
    end
  end

  it "fails when libraries are not required" do
    script = tmp_root.join("fail_sanity_check")
    File.open(script, "w") do |f|
      f.write <<-EOF.gsub(/^\s+\|/, '')
        |#!/usr/bin/env ruby
        |RSpec::Support.require_rspec_core "project_initializer"
      EOF
    end
    FileUtils.chmod 0777, script

    with_clean_env do
      expect(`bundle exec #{script} 2>&1`)
        .to match(/uninitialized constant RSpec::Support/)
        .or match(/undefined method `require_rspec_core' for RSpec::Support:Module/)

      expect($?.exitstatus).to eq(1)
    end
  end

  it "passes when libraries are required", skip: RSpec::Support::Ruby.jruby? do
    script = tmp_root.join("pass_sanity_check")
    File.open(script, "w") do |f|
      f.write <<-EOF.gsub(/^\s+\|/, '')
        |#!/usr/bin/env ruby
        |require 'rspec/core'
        |require 'rspec/support'
        |RSpec::Support.require_rspec_core "project_initializer"
      EOF
    end
    FileUtils.chmod 0777, script

    with_clean_env do
      expect(`bundle exec #{script} 2>&1`).to be_empty
      expect($?.exitstatus).to eq(0)
    end
  end

end
