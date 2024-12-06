require 'spec_helper'
require 'pathname'

describe Launchy do

  before do
    Launchy.reset_global_options
    @stderr  = $stderr
    $stderr = StringIO.new
    @stdout = $stdout
    $stdout = StringIO.new
    @invalid_url = 'blah://example.com/invalid'
  end

  after do
    Launchy.reset_global_options
    $stderr = @stderr
    $stdout = @stdout
  end

  it "logs to stderr when LAUNCHY_DEBUG environment variable is set" do
    ENV["LAUNCHY_DEBUG"] = 'true'
    old_stderr = $stderr
    $stderr = StringIO.new
    Launchy.log "This is a test log message"
    _($stderr.string.strip).must_equal "LAUNCHY_DEBUG: This is a test log message"
    $stderr = old_stderr
    ENV["LAUNCHY_DEBUG"] = nil
  end

  it "sets the global option :dry_run to true if LAUNCHY_DRY_RUN environment variable is 'true'" do
    ENV['LAUNCHY_DRY_RUN'] = 'true'
    Launchy.extract_global_options({})
    _(Launchy.dry_run?).must_equal true
    ENV['LAUNCHY_DRY_RUN'] = nil
  end

  it "sets the global option :debug to true if LAUNCHY_DEBUG environment variable is 'true'" do
    ENV['LAUNCHY_DEBUG'] = 'true'
    Launchy.extract_global_options({})
    _(Launchy.debug?).must_equal true
    ENV['LAUNCHY_DEBUG'] = nil
  end

  it "has the global option :debug" do
    Launchy.extract_global_options( { :debug => 'true' } )
    _(Launchy.debug?).must_equal true
    Launchy.extract_global_options( { :debug => true } )
    _(Launchy.debug?).must_equal true
  end

  it "has the global option :dry_run" do
    Launchy.extract_global_options( { :dry_run => 'true' } )
    _(Launchy.dry_run?).must_equal true
    Launchy.extract_global_options( { :dry_run => true } )
    _(Launchy.dry_run?).must_equal true
  end

  it "has the global option :application" do
    Launchy.extract_global_options(  { :application => "wibble" } )
    _(Launchy.application).must_equal 'wibble'
  end

  it "has the global option :host_os" do
    Launchy.extract_global_options(  { :host_os => "my-special-os-v2" } )
    _(Launchy.host_os).must_equal 'my-special-os-v2'
  end

  it "has the global option :ruby_engine" do
    Launchy.extract_global_options(  { :ruby_engine => "myruby" } )
    _(Launchy.ruby_engine).must_equal 'myruby'
  end

  it "raises an exception if no scheme is found for the given uri" do
    _(lambda { Launchy.open( @invalid_url ) }).must_raise Launchy::ApplicationNotFoundError
  end

  it "asssumes we open a local file if we have an exception if we have an invalid scheme and a valid path" do
    uri = "blah://example.com/#{__FILE__}"
    Launchy.open( uri , :dry_run => true )
    parts = $stdout.string.strip.split
    _(parts.size).must_be :>, 1
    _(parts.last).must_equal uri
  end

  it "opens a local file if we have a drive letter and a valid path on windows" do
    uri = "C:#{__FILE__}"
    Launchy.open( uri, :dry_run => true, :host_os => 'windows'  )
    _($stdout.string.strip).must_equal 'cmd /c start "launchy" /b ' + uri
  end

  it "calls the block if instead of raising an exception if there is an error" do
    Launchy.open( @invalid_url ) { $stderr.puts "oops had an error opening #{@invalid_url}" }
    _($stderr.string.strip).must_equal "oops had an error opening #{@invalid_url}"
  end

  it "calls the block with the values passed to launchy and the error" do
    options = { :dry_run => true }
    Launchy.open( @invalid_url, :dry_run => true ) { |e| $stderr.puts "had an error opening #{@invalid_url} with options #{options}: #{e}" }
    _($stderr.string.strip).must_equal "had an error opening #{@invalid_url} with options #{options}: No application found to handle '#{@invalid_url}'"
  end

  it "raises the error in the called block" do
    _(lambda { Launchy.open( @invalid_url ) { raise StandardError, "KABOOM!" } }).must_raise StandardError
  end

  [ 'www.example.com', 'www.example.com/foo/bar', "C:#{__FILE__}" ].each do |x|
    it "picks a Browser for #{x}" do
      app = Launchy.app_for_uri_string( x )
      _(app).must_equal( Launchy::Application::Browser )
    end
  end

  it "can use a Pathname as the URI" do
    path = Pathname.new( Dir.pwd )
    app = Launchy.app_for_uri_string( path )
    _(app).must_equal( Launchy::Application::Browser )
  end
end
