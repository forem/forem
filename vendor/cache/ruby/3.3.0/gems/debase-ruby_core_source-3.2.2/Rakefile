require 'tmpdir'
require 'open-uri'
require 'archive/tar/minitar'
require 'zlib'
require 'fileutils'
require 'bundler'
Bundler::GemHelper.install_tasks

def get_dest_dir(ruby_dir, version, tempdir)
  dest_dir = File.dirname(__FILE__) + "/lib/debase/ruby_core_source/#{ruby_dir}"
  return dest_dir if version.include?('-p')

  patchlevel = ENV['PATCHLEVEL']
  if !patchlevel
    puts "extracting patchlevel from version.h"
    patchlevel = File.new("#{tempdir}/#{ruby_dir}/version.h").each_line.map do |li|
      if /#define RUBY_PATCHLEVEL (-?\d+)/ =~ li
        break $1
      else
        nil
      end
    end#.find { |p| not p.nil?}
    puts "extracted patchlevel '#{patchlevel}'"
  end
  if patchlevel
    dest_dir = dest_dir + "-p" + patchlevel unless patchlevel == '-1'
  else
    warn "Unable to extract patchlevel from verion.h assuming there is no patchlevel please use a $PATCHLEVEL to specify one"
  end
  dest_dir
end

desc <<DESCR
Add ruby headers under lib for a given VERSION and (optional) PATCHLEVEL,
\t\t\tif patchlevel is not provided it will be extracted from version.h.
\t\t\tTGZ_FILE_NAME can be used to provide pre-downloaded tgz file
DESCR
task :add_source do
  version = ENV['VERSION'] or abort "Need a $VERSION"
  ruby_dir = "ruby-#{version}"

  if ENV['TGZ_FILE_NAME']
    temp = ENV['TGZ_FILE_NAME']
    puts "Using pre-downloaded bundle #{temp}"
  else
    minor_version = version.split('.')[0..1].join('.')
    uri_path = "http://ftp.ruby-lang.org/pub/ruby/#{minor_version}/#{ruby_dir}.tar.gz"
    puts "Downloading #{uri_path}..."
    temp = URI.open(uri_path)
  end
  puts "Unpacking #{uri_path}..."
  tgz = Zlib::GzipReader.new(File.open(temp, "rb"))

  Dir.mktmpdir do |dir|
    inc_dir = dir + "/" + ruby_dir + "/*.inc"
    hdr_dir = dir + "/" + ruby_dir + "/*.h"
    more_hdr_dir = [
      dir + "/" + ruby_dir + "/ccan/**/*.h",
      dir + "/" + ruby_dir + "/internal/**/*.h"
    ]
    Archive::Tar::Minitar.unpack(tgz, dir)

    dest_dir = get_dest_dir(ruby_dir, version, dir)
    puts dest_dir
    FileUtils.mkdir_p(dest_dir)
    Dir.glob([ inc_dir, hdr_dir, more_hdr_dir ].flatten).each do |file|
      target = file.sub(dir + '/' + ruby_dir, dest_dir)
      FileUtils.mkdir_p(File.dirname(target))
      FileUtils.cp(file, target, verbose: false)
    end
  end
end

