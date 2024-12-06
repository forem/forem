require 'spec_helper'
require 'mock_application'

class JunkApp < Launchy::Application
  def self.handles?( uri )
    uri.scheme == "junk"
  end
end

describe Launchy::Application do
  it 'registers inherited classes' do
    class Junk2App < Launchy::Application
      def self.handles?( uri )
        uri.scheme == "junk2"
      end
    end
    _(Launchy::Application.children).must_include( Junk2App )
    Launchy::Application.children.delete( Junk2App )
  end

  it "can find an app" do
    _(Launchy::Application.children).must_include( JunkApp )
    _(Launchy::Application.children.size).must_equal 3
    uri = Addressable::URI.parse( "junk:///foo" )
    _(Launchy::Application.handling( uri )).must_equal( JunkApp  )
  end

  it "raises an error if an application cannot be found for the given scheme" do
    uri = Addressable::URI.parse( "foo:///bar" )
    _(lambda { Launchy::Application.handling( uri ) }).must_raise( Launchy::ApplicationNotFoundError )
  end

  it "can find open or curl or xdg-open" do
    found = %w[ open curl xdg-open ].any? do |app|
      Launchy::Application.find_executable( app )
    end
    _(found).must_equal true
  end

  it "does not find xyzzy" do
    _(Launchy::Application.find_executable( "xyzzy" )).must_be_nil
  end
end
