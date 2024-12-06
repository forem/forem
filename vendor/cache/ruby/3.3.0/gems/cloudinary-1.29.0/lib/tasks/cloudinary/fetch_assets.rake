require 'tmpdir'
require 'rest_client'
require 'json'
require 'rubygems/package'

unless Rake::Task.task_defined?('cloudinary:fetch_assets') # prevent double-loading/execution
  namespace :cloudinary do
    desc "Fetch the latest JavaScript library files and create the JavaScript index files"
    task :fetch_assets do
      index_files = %w[jquery.ui.widget.js jquery.iframe-transport.js jquery.fileupload.js jquery.cloudinary.js]
      processing_files = %w[canvas-to-blob.min.js load-image.all.min.js jquery.fileupload-process.js jquery.fileupload-image.js jquery.fileupload-validate.js]
      files = index_files + processing_files

      release = JSON(RestClient.get("https://api.github.com/repos/cloudinary/cloudinary_js/releases/latest"))

      FileUtils.rm_rf 'vendor/assets'
      html_folder = 'vendor/assets/html'
      FileUtils.mkdir_p html_folder
      js_folder = 'vendor/assets/javascripts/cloudinary'
      FileUtils.mkdir_p js_folder

      puts "Fetching cloudinary_js version #{release["tag_name"]}\n\n"
      sio = StringIO.new(RestClient.get(release["tarball_url"]).body)
      file = Zlib::GzipReader.new(sio)
      tar = Gem::Package::TarReader.new(file)
      tar.each_entry do |entry|
        name = File.basename(entry.full_name)
        if files.include? name
          js_full_name = File.join(js_folder, name)
          puts "Adding #{js_full_name}"
          File.write js_full_name, entry.read
        elsif name == 'cloudinary_cors.html'
          html_full_name = File.join(html_folder, name)
          puts "Adding #{html_full_name}"
          File.write html_full_name, entry.read
        end
      end
      puts "Creating 'index.js' and 'processing.js' files"
      File.open("vendor/assets/javascripts/cloudinary/index.js", "w") do |f|
        index_files.each { |name| f.puts "//= require ./#{name}" }
      end
      File.open("vendor/assets/javascripts/cloudinary/processing.js", "w") do |f|
        processing_files.each { |name| f.puts "//= require ./#{name}" }
      end
    end

  end
end
