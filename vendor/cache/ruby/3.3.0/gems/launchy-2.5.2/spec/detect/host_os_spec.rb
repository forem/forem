require 'spec_helper'

describe Launchy::Detect::HostOs do

  it "uses the defult host os from ruby's config" do
    _(Launchy::Detect::HostOs.new.host_os).must_equal RbConfig::CONFIG['host_os']
  end

  it "uses the passed in value as the host os" do
    _(Launchy::Detect::HostOs.new( "fake-os-1").host_os).must_equal "fake-os-1"
  end

  it "uses the environment variable LAUNCHY_HOST_OS to override ruby's config" do
    ENV['LAUNCHY_HOST_OS'] = "fake-os-2"
    _(Launchy::Detect::HostOs.new.host_os).must_equal "fake-os-2"
    ENV.delete('LAUNCHY_HOST_OS')
  end

end
