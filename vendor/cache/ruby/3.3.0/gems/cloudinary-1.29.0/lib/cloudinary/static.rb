require 'find'
require 'time'
require 'set'
class Cloudinary::Static
  IGNORE_FILES = [".svn", "CVS", "RCS", ".git", ".hg"]
  DEFAULT_IMAGE_DIRS = ["app/assets/images", "lib/assets/images", "vendor/assets/images", "public/images"]
  DEFAULT_IMAGE_EXTENSION_MASK = 'gif|jpe?g|png|bmp|ico|webp|wdp|jxr|jp2|svg|pdf'
  METADATA_FILE = ".cloudinary.static"
  METADATA_TRASH_FILE = ".cloudinary.static.trash"

  class << self
    def sync(options={})
      options = options.clone
      delete_missing = options.delete(:delete_missing)
      found_paths = Set.new
      found_public_paths = {}
      found_public_ids = Set.new
      metadata = build_metadata
      metadata_lines = []
      counts = { :not_changed => 0, :uploaded => 0, :deleted => 0, :not_found => 0}
      discover_all do |path, public_path|
        next if found_paths.include?(path)
        if found_public_paths[public_path]
          print "Warning: duplicate #{public_path} in #{path} - already taken from #{found_public_paths[public_path]}\n"
          next
        end
        found_paths << path
        found_public_paths[public_path] = path
        data = root.join(path).read(:mode=>"rb")
        ext = path.extname
        format = ext[1..-1]
        md5 = Digest::MD5.hexdigest(data)
        public_id = "#{public_path.basename(ext)}-#{md5}"
        found_public_ids << public_id
        item_metadata = metadata.delete(public_path.to_s)
        if item_metadata && item_metadata["public_id"] == public_id # Signature match
          counts[:not_changed] += 1
          print "#{public_path} - #{public_id} - Not changed\n"
          result = item_metadata
        else
          counts[:uploaded] += 1
          print "#{public_path} - #{public_id} - Uploading\n"
          result = Cloudinary::Uploader.upload(Cloudinary::Blob.new(data, :original_filename=>path.to_s),
            options.merge(:format=>format, :public_id=>public_id, :type=>:asset, :resource_type=>resource_type(path.to_s))
          ).merge("upload_time"=>Time.now)
        end
        metadata_lines << [public_path, public_id, result["upload_time"].to_i, result["version"], result["width"], result["height"]].join("\t")+"\n"
      end
      File.open(metadata_file_path, "w"){|f| f.print(metadata_lines.join)}
      metadata.to_a.each do |path, info|
        counts[:not_found] += 1
        print "#{path} - #{info["public_id"]} - Not found\n"      
      end
      # Files no longer needed 
      trash = metadata.to_a + build_metadata(metadata_trash_file_path, false).reject{|public_path, info| found_public_ids.include?(info["public_id"])}
      
      if delete_missing
        trash.each do
          |path, info|
          counts[:deleted] += 1
          print "#{path} - #{info["public_id"]} - Deleting\n"
          Cloudinary::Uploader.destroy(info["public_id"], options.merge(:type=>:asset))
        end
        FileUtils.rm_f(metadata_trash_file_path)
      else
        # Add current removed file to the trash file.
        metadata_lines = trash.map do
          |public_path, info|
          [public_path, info["public_id"], info["upload_time"].to_i, info["version"], info["width"], info["height"]].join("\t")+"\n"
        end
        File.open(metadata_trash_file_path, "w"){|f| f.print(metadata_lines.join)}
      end
  
      print "\nCompleted syncing static resources to Cloudinary\n"
      print counts.sort.reject{|k,v| v == 0}.map{|k,v| "#{v} #{k.to_s.gsub('_', ' ').capitalize}"}.join(", ") + "\n"
    end

    # ## Cloudinary::Utils support ###
    def public_id_and_resource_type_from_path(path)
      @metadata ||= build_metadata
      path = path.sub(/^\//, '')
      prefix = public_prefixes.find {|prefix| @metadata[File.join(prefix, path)]}
      if prefix
        [@metadata[File.join(prefix, path)]['public_id'], resource_type(path)]
      else
        nil
      end
    end

    private
    def root
      Cloudinary.app_root
    end

    def metadata_file_path
      root.join(METADATA_FILE)
    end

    def metadata_trash_file_path
      root.join(METADATA_TRASH_FILE)
    end

    def build_metadata(metadata_file = metadata_file_path, hash = true)
      metadata = []
      if File.exist?(metadata_file)
        IO.foreach(metadata_file) do
        |line|
          line.strip!
          next if line.blank?
          path, public_id, upload_time, version, width, height = line.split("\t")
          metadata << [path, {
            "public_id" => public_id,
            "upload_time" => Time.at(upload_time.to_i).getutc,
            "version" => version,
            "width" => width.to_i,
            "height" => height.to_i
          }]
        end
      end
      hash ? Hash[*metadata.flatten] : metadata
    end

    def discover_all(&block)
      static_file_config.each do |group, data|
        print "-> Syncing #{group}...\n"
        discover(absolutize(data['dirs']), extension_matcher_for(group), &block)
        print "=========================\n"
      end
    end

    def discover(dirs, matcher)
      return unless matcher

      dirs.each do |dir|
        print "Scanning #{dir.relative_path_from(root)}...\n"
        dir.find do |path|
          file = path.basename.to_s
          if ignore_file?(file)
            Find.prune
            next
          elsif path.directory? || !matcher.call(path.to_s)
            next
          else
            relative_path = path.relative_path_from(root)
            public_path = path.relative_path_from(dir.dirname)
            yield(relative_path, public_path)
          end
        end
      end
    end

    def ignore_file?(file)
      matches?(file, Cloudinary.config.ignore_files || IGNORE_FILES)
    end

    # Test for matching either strings or regexps
    def matches?(target, patterns)
      Array(patterns).any? {|pattern| pattern.is_a?(String) ? pattern == target : target.match(pattern)}
    end

    def extension_matcher_for(group)
      group = group.to_s
      return unless static_file_config[group]
      @matchers = {}
      @matchers[group] ||= ->(target) do
        !!target.match(extension_mask_to_regex(static_file_config[group]['file_mask']))
      end
    end

    def static_file_config
      @static_file_config ||= begin
        config = Cloudinary.config.static_files || {}

        # Default
        config['images'] ||= {}
        config['images']['dirs'] ||= Cloudinary.config.static_image_dirs # Backwards compatibility
        config['images']['dirs'] ||= DEFAULT_IMAGE_DIRS
        config['images']['file_mask'] ||= DEFAULT_IMAGE_EXTENSION_MASK
        # Validate
        config.each do |group, data|
          unless data && data['dirs'] && data['file_mask']
            print "In config, static_files group '#{group}' needs to have both 'dirs' and 'file_mask' defined.\n"
            exit
          end
        end

        config
      end
    end

    def reset_static_file_config!
      @static_file_config = nil
    end

    def image?(path)
      extension_matcher_for(:images).call(path)
    end

    def resource_type(path)
      if image?(path)
        :image
      else
        :raw
      end
    end

    def extension_mask_to_regex(extension_mask)
      extension_mask && /\.(?:#{extension_mask})$/i
    end

    def public_prefixes
      @public_prefixes ||= static_file_config.reduce([]) do |result, (group, data)|
        result << data['dirs'].map { |dir| Pathname.new(dir).basename.to_s }
      end.flatten.uniq
    end

    def absolutize(dirs)
      dirs.map do |relative_dir|
        absolute_dir = root.join(relative_dir)
        if absolute_dir.exist?
          absolute_dir
        else
          print "Skipping #{relative_dir} (does not exist)\n"
          nil
        end
      end.compact
    end
    
    def print(s)
      $stderr.print(s)
    end
  end
end