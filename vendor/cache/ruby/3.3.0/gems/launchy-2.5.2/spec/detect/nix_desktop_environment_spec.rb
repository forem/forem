require 'spec_helper'

describe Launchy::Detect::NixDesktopEnvironment do

  before do
    Launchy.reset_global_options
  end

  after do
    Launchy.reset_global_options
  end

  it "returns false for XFCE if xprop is not found" do
    Launchy.host_os = "linux"
    _(Launchy::Detect::NixDesktopEnvironment::Xfce.is_current_desktop_environment?).must_equal( false )
  end

  it "returns NotFound if it cannot determine the *nix desktop environment" do
    Launchy.host_os = "linux"
    ENV.delete( "KDE_FULL_SESSION" )
    ENV.delete( "GNOME_DESKTOP_SESSION_ID" )
    Launchy.path = %w[ / /tmp ].join(File::PATH_SEPARATOR)
    not_found = Launchy::Detect::NixDesktopEnvironment.detect
    _(not_found).must_equal( Launchy::Detect::NixDesktopEnvironment::NotFound )
    _(not_found.browser).must_equal( Launchy::Argv.new )
  end
end
