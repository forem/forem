class Version < Thor
  include Thor::Actions

  desc "use VERSION", "installs the bundle the rails-VERSION"
  def use(version)
    remove_file "Gemfile.lock"
    run "echo '#{version}' > ./.rails-version"
    run "bundle install --binstubs"
  end

  desc "which", "print out the configured rails version"
  def which
    say `cat ./.rails-version`
  end
end
