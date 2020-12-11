require 'tmpdir'
require 'fileutils'
require 'pathname'

RSpec.shared_context "isolated home directory" do
  around do |ex|
    Dir.mktmpdir do |tmp_dir|
      # If user running this test suite has a custom $XDG_CONFIG_HOME, also
      # clear that out when changing $HOME so tests don't touch the user's real
      # configuration files.
      without_env_vars "XDG_CONFIG_HOME" do
        with_env_vars "HOME" => tmp_dir do
          ex.call
        end
      end
    end
  end
end

module HomeFixtureHelpers
  def create_fixture_file(file_name, contents)
    path = Pathname.new(file_name).expand_path
    if !path.exist?
      path.dirname.mkpath
      # Pathname#write does not exist in all supported Ruby versions
      File.open(path.to_s, 'w') { |file| file << contents }
    else
      # Abort just in case we're about to destroy something important.
      raise "File at #{path} already exists!"
    end
  end
end

RSpec.configure do |c|
  c.include_context "isolated home directory", :isolated_home => true
  c.include HomeFixtureHelpers, :isolated_home => true
end
