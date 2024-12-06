# encoding: utf-8
# frozen_string_literal: true

require 'fileutils'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

def version
  ENV.fetch('VERSION')
end

HEADER = "## next"

def changelog_tail
  changelog = File.read("CHANGELOG.md")
  if changelog.start_with?(HEADER)
    changelog[HEADER.length + 2..-1]
  else
    "\n#{changelog}"
  end
end

def compare_url(from, to)
  "https://github.com/terser/terser/compare/#{from}...#{to}"
end

def previous_version
  match = File.read("CHANGELOG.md").scan(/- update Terser to \[(.*)\]\(/)
  match ? match[0][0].chomp : nil
end

def git_commit(files, message)
  `git add #{files.join(' ')}`
  `git commit -S -m "#{message.gsub('"', "\\\"")}"`
end

# rubocop:disable Metrics/BlockLength
namespace :terser do
  desc "Update Terser source to version specified in VERSION environment variable"
  task :update do
    cd 'vendor/terser' do
      `git fetch && git checkout v#{version}`
    end
  end

  desc "Rebuild lib/terser*.js"
  task :build do
    cd 'vendor/source-map/' do
      `npm install --no-package-lock --no-save`
    end

    cd 'vendor/terser/' do
      FileUtils.rm_rf("package-lock.json")
      `npm install --no-package-lock --no-save`
    end

    # FileUtils.cp("vendor/source-map/dist/source-map.min.js", "lib/source-map.js")

    FileUtils.cp("vendor/source-map/dist/source-map.js", "lib/source-map.js")

    FileUtils.cp("vendor/terser/dist/bundle.min.js", "lib/terser.js")

    # minified_source = `node ./vendor/terser/bin/terser vendor/terser/dist/bundle.min.js`
    # File.write("lib/terser.js", minified_source)

    FileUtils.cp("vendor/split/split.js", "lib/split.js")
    `patch -p1 -i patches/es5-string-split.patch`
  end

  desc "Add Terser version bump to changelog"
  task :changelog do
    url = compare_url("v#{previous_version}", "v#{version}")
    item = "- update Terser to [#{version}](#{url})"
    changelog = "#{HEADER}\n\n#{item}\n#{changelog_tail}"
    File.write("CHANGELOG.md", changelog)
  end

  desc "Commit changes from Terser version bump"
  task :commit do
    files = [
      'CHANGELOG.md',
      'lib/terser.js',
      'vendor/terser'
    ]
    git_commit(files, "Update Terser to #{version}")
  end
end
# rubocop:enable Metrics/BlockLength

desc "Update Terser to version specified in VERSION environment variable"
task :terser => ['terser:update', 'terser:build', 'terser:changelog', 'terser:commit']

namespace :version do
  desc "Write version to CHANGELOG.md"
  task :changelog do
    content = File.read("CHANGELOG.md")
    date = Time.now.strftime("%d %B %Y")
    File.write("CHANGELOG.md", content.gsub("## next", "## #{version} (#{date})"))
  end

  desc "Write version"
  task :ruby do
    file = "lib/terser/version.rb"
    content = File.read("lib/terser/version.rb")
    File.write(file, content.gsub(/VERSION = "(.*)"/, "VERSION = \"#{version}\""))
  end

  desc "Commit changes from Terser version bump"
  task :commit do
    files = ["CHANGELOG.md", "lib/terser/version.rb"]
    git_commit(files, "Bump version to #{version}")
  end

  desc "Create git tag for version"
  task :tag do
    `git tag -s -m "Version #{version}" v#{version}`
  end
end

desc "Update Terser to version specified in VERSION environment variable"
task :version => ['version:changelog', 'version:ruby', 'version:commit', 'version:tag']

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new(:rubocop)
  task :default => [:rubocop, :spec]
rescue LoadError
  task :default => [:spec]
end
