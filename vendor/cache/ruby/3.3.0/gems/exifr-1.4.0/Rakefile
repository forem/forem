# Copyright (c) 2006-2020 - R.W. van 't Veer

require 'rake/testtask'

task :default => :test

Rake::TestTask.new do |t|
  t.libs << 'lib' << 'tests'
  t.test_files = FileList['tests/*_test.rb']
  t.warning = true
end

begin
  begin
    require 'rdoc/task'
  rescue LoadError
    require 'rake/rdoctask'
  end

  desc 'Generate site'
  task :site => :rdoc do
    system 'rsync -av --delete doc/ remvee@rubyforge.org:/var/www/gforge-projects/exifr'
  end

  Rake::RDocTask.new do |rd|
    rd.title = 'EXIF Reader for Ruby API Documentation'
    rd.main = "README.rdoc"
    rd.rdoc_dir = "doc/api"
    rd.rdoc_files.include("README.rdoc", "lib/**/*.rb")
  end

  desc 'Remove all artifacts left by testing and packaging'
  task :clean => [:clobber_rdoc]

rescue StandardError
  nil
end
