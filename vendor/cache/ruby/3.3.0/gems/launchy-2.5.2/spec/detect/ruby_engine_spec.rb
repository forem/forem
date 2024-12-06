require 'spec_helper'

describe Launchy::Detect::RubyEngine do

  before do
    Launchy.reset_global_options
  end

  after do
    Launchy.reset_global_options
  end

  %w[ ruby jruby rbx macruby ].each do |ruby|
    it "detects the #{ruby} RUBY_ENGINE" do
      _(Launchy::Detect::RubyEngine.detect( ruby ).ancestors).must_include Launchy::Detect::RubyEngine
    end
  end

  it "uses the global ruby_engine overrides" do
    ENV['LAUNCHY_RUBY_ENGINE'] = "rbx"
    _(Launchy::Detect::RubyEngine.detect).must_equal Launchy::Detect::RubyEngine::Rbx
    ENV.delete('LAUNCHY_RUBY_ENGINE')
  end

  it "does not find a ruby engine of 'foo'" do
    _(lambda { Launchy::Detect::RubyEngine.detect( 'foo' ) }).must_raise Launchy::Detect::RubyEngine::NotFoundError
  end

  { 'rbx'     => :rbx?,
    'ruby'    => :mri?,
    'macruby' => :macruby?,
    'jruby'   => :jruby? }.each_pair do |engine, method|
    it "#{method} returns true for #{engine} " do
      _(Launchy::Detect::RubyEngine.detect( engine ).send( method )).must_equal true
    end
 end
end
