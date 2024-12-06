namespace :javascript do
  desc "Install JavaScript dependencies"
  task :install do
    command = Jsbundling::Tasks.install_command
    unless system(command)
      raise "jsbundling-rails: Command install failed, ensure #{command.split.first} is installed"
    end
  end

  desc "Build your JavaScript bundle"
  build_task = task :build do
    command = Jsbundling::Tasks.build_command
    unless system(command)
      raise "jsbundling-rails: Command build failed, ensure `#{command}` runs without errors"
    end
  end

  build_task.prereqs << :install unless ENV["SKIP_YARN_INSTALL"] || ENV["SKIP_BUN_INSTALL"]
end

module Jsbundling
  module Tasks
    extend self

    def install_command
      case tool
      when :bun then "bun install"
      when :yarn then "yarn install"
      when :pnpm then "pnpm install"
      when :npm then "npm install"
      else raise "jsbundling-rails: No suitable tool found for installing JavaScript dependencies"
      end
    end

    def build_command
      case tool
      when :bun then "bun run build"
      when :yarn then "yarn build"
      when :pnpm then "pnpm build"
      when :npm then "npm run build"
      else raise "jsbundling-rails: No suitable tool found for building JavaScript"
      end
    end

    def tool_exists?(tool)
      system "command -v #{tool} > /dev/null"
    end

    def tool
      case
      when File.exist?('bun.lockb') then :bun
      when File.exist?('yarn.lock') then :yarn
      when File.exist?('pnpm-lock.yaml') then :pnpm
      when File.exist?('package-lock.json') then :npm
      when tool_exists?('bun') then :bun
      when tool_exists?('yarn') then :yarn
      when tool_exists?('pnpm') then :pnpm
      when tool_exists?('npm') then :npm
      end
    end
  end
end

unless ENV["SKIP_JS_BUILD"]
  if Rake::Task.task_defined?("assets:precompile")
    Rake::Task["assets:precompile"].enhance(["javascript:build"])
  end

  if Rake::Task.task_defined?("test:prepare")
    Rake::Task["test:prepare"].enhance(["javascript:build"])
  elsif Rake::Task.task_defined?("spec:prepare")
    Rake::Task["spec:prepare"].enhance(["javascript:build"])
  elsif Rake::Task.task_defined?("db:test:prepare")
    Rake::Task["db:test:prepare"].enhance(["javascript:build"])
  end
end
