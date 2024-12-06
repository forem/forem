namespace :acts_as_taggable_on do

  namespace :sharded_db do

    desc "Install initializer setting custom base class"
    task :install_initializer => [:environment, "config/initializers/foo"] do
      source = File.join(
        Gem.loaded_specs["acts-as-taggable-on"].full_gem_path,
        "lib",
        "tasks",
        "examples",
        "acts_as_taggable_on.rb.example"
      )

      destination = "config/initializers/acts_as_taggable_on.rb"

      cp source, destination
    end

    directory "config/initializers"
  end

end
