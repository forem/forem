# encoding: utf-8

require "rubygems/package_task"
require "rake/extensiontask"
require "rake/testtask"
require "rdoc/task"
require "date"
require "rake/clean"

# To release a version of ruby-prof:
#   * Update lib/ruby-prof/version.rb
#   * Update CHANGES
#   * git commit to commit files
#   * rake clobber to remove extra files
#   * rake compile to build windows gems
#   * rake package to create the gems
#   * Tag the release (git tag 0.10.1)
#   * Push to ruybgems.org (gem push pkg/<gem files>)

GEM_NAME = 'ruby-prof'
SO_NAME = 'ruby_prof'

default_spec = Gem::Specification.load("#{GEM_NAME}.gemspec")

# specify which versions/builds to cross compile
Rake::ExtensionTask.new do |ext|
  ext.gem_spec = default_spec
  ext.name = SO_NAME
  ext.ext_dir = "ext/#{SO_NAME}"
  ext.lib_dir = "lib/#{Gem::Version.new(RUBY_VERSION).segments[0..1].join('.')}"
  ext.cross_compile = true
  ext.cross_platform = ['x64-mingw32']
end

# Rake task to build the default package
Gem::PackageTask.new(default_spec) do |pkg|
  pkg.need_tar = true
end

# make sure rdoc has been built when packaging
# why do we ship rdoc as part of the gem?
Rake::Task[:package].enhance [:rdoc]

# Setup Windows Gem
if RUBY_PLATFORM.match(/mswin|mingw/)
  # Windows specification
  win_spec = default_spec.clone
  win_spec.platform = Gem::Platform::CURRENT
  win_spec.files += Dir.glob('lib/**/*.so')

  # Unset extensions
  win_spec.extensions = nil

  # Rake task to build the windows package
  Gem::PackageTask.new(win_spec) do |pkg|
    pkg.need_tar = false
  end
end

# ---------  RDoc Documentation ------
desc "Generate rdoc documentation"
RDoc::Task.new("rdoc") do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title = "ruby-prof"
  # Show source inline with line numbers
  rdoc.options << "--line-numbers"
  # Make the readme file the start page for the generated html
  rdoc.options << '--main' << 'README.md'
  rdoc.rdoc_files.include('bin/*',
                          'doc/*.rdoc',
                          'lib/**/*.rb',
                          'ext/ruby_prof/*.c',
                          'ext/ruby_prof/*.h',
                          'README.md',
                          'LICENSE')
end

task :default => :test

for file in Dir['lib/**/*.{o,so,bundle}']
  CLEAN.include file
end
for file in Dir['doc/**/*.{txt,dat,png,html}']
  CLEAN.include file
end
CLEAN.reject!{|f| !File.exist?(f)}
task :clean do
  # remove tmp dir contents completely after cleaning
  FileUtils.rm_rf('tmp/*')
end

desc 'Run the ruby-prof test suite'
Rake::TestTask.new do |t|
  t.libs += %w(lib ext test)
  t.test_files = Dir['test/**_test.rb']
  t.verbose = true
  t.warning = true
end
