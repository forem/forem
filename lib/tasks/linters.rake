if %w(development test).include? Rails.env
  namespace :lint do
    desc "eslint"
    task :eslint do
      cmd = "cd client && npm run eslint . -- --ext .jsx,.js"
      puts "Running eslint via `#{cmd}`"
      sh cmd
    end

    desc "jscs"
    task :jscs do
      cmd = "cd client && npm run jscs ."
      puts "Running jscs via `#{cmd}`"
      sh cmd
    end

    desc "JS Linting"
    task js: [:eslint, :jscs] do
      puts "Completed running all JavaScript Linters"
    end

    task lint: [:js] do
      puts "Completed all linting"
    end
  end

  desc "Runs all linters. Run `rake -D lint` to see all available lint options"
  task lint: ["lint:lint"]
end
