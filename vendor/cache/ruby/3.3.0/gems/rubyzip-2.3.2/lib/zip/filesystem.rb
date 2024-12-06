require 'zip'

module Zip
  # The ZipFileSystem API provides an API for accessing entries in
  # a zip archive that is similar to ruby's builtin File and Dir
  # classes.
  #
  # Requiring 'zip/filesystem' includes this module in Zip::File
  # making the methods in this module available on Zip::File objects.
  #
  # Using this API the following example creates a new zip file
  # <code>my.zip</code> containing a normal entry with the name
  # <code>first.txt</code>, a directory entry named <code>mydir</code>
  # and finally another normal entry named <code>second.txt</code>
  #
  #   require 'zip/filesystem'
  #
  #   Zip::File.open("my.zip", Zip::File::CREATE) {
  #     |zipfile|
  #     zipfile.file.open("first.txt", "w") { |f| f.puts "Hello world" }
  #     zipfile.dir.mkdir("mydir")
  #     zipfile.file.open("mydir/second.txt", "w") { |f| f.puts "Hello again" }
  #   }
  #
  # Reading is as easy as writing, as the following example shows. The
  # example writes the contents of <code>first.txt</code> from zip archive
  # <code>my.zip</code> to standard out.
  #
  #   require 'zip/filesystem'
  #
  #   Zip::File.open("my.zip") {
  #     |zipfile|
  #     puts zipfile.file.read("first.txt")
  #   }

  module FileSystem
    def initialize # :nodoc:
      mapped_zip       = ZipFileNameMapper.new(self)
      @zip_fs_dir      = ZipFsDir.new(mapped_zip)
      @zip_fs_file     = ZipFsFile.new(mapped_zip)
      @zip_fs_dir.file = @zip_fs_file
      @zip_fs_file.dir = @zip_fs_dir
    end

    # Returns a ZipFsDir which is much like ruby's builtin Dir (class)
    # object, except it works on the Zip::File on which this method is
    # invoked
    def dir
      @zip_fs_dir
    end

    # Returns a ZipFsFile which is much like ruby's builtin File (class)
    # object, except it works on the Zip::File on which this method is
    # invoked
    def file
      @zip_fs_file
    end

    # Instances of this class are normally accessed via the accessor
    # Zip::File::file. An instance of ZipFsFile behaves like ruby's
    # builtin File (class) object, except it works on Zip::File entries.
    #
    # The individual methods are not documented due to their
    # similarity with the methods in File
    class ZipFsFile
      attr_writer :dir
      # protected :dir

      class ZipFsStat
        class << self
          def delegate_to_fs_file(*methods)
            methods.each do |method|
              class_eval <<-END_EVAL, __FILE__, __LINE__ + 1
                def #{method}                      # def file?
                  @zip_fs_file.#{method}(@entry_name) #   @zip_fs_file.file?(@entry_name)
                end                                # end
              END_EVAL
            end
          end
        end

        def initialize(zip_fs_file, entry_name)
          @zip_fs_file = zip_fs_file
          @entry_name = entry_name
        end

        def kind_of?(type)
          super || type == ::File::Stat
        end

        delegate_to_fs_file :file?, :directory?, :pipe?, :chardev?, :symlink?,
                            :socket?, :blockdev?, :readable?, :readable_real?, :writable?, :ctime,
                            :writable_real?, :executable?, :executable_real?, :sticky?, :owned?,
                            :grpowned?, :setuid?, :setgid?, :zero?, :size, :size?, :mtime, :atime

        def blocks
          nil
        end

        def get_entry
          @zip_fs_file.__send__(:get_entry, @entry_name)
        end
        private :get_entry

        def gid
          e = get_entry
          if e.extra.member? 'IUnix'
            e.extra['IUnix'].gid || 0
          else
            0
          end
        end

        def uid
          e = get_entry
          if e.extra.member? 'IUnix'
            e.extra['IUnix'].uid || 0
          else
            0
          end
        end

        def ino
          0
        end

        def dev
          0
        end

        def rdev
          0
        end

        def rdev_major
          0
        end

        def rdev_minor
          0
        end

        def ftype
          if file?
            'file'
          elsif directory?
            'directory'
          else
            raise StandardError, 'Unknown file type'
          end
        end

        def nlink
          1
        end

        def blksize
          nil
        end

        def mode
          e = get_entry
          if e.fstype == 3
            e.external_file_attributes >> 16
          else
            33_206 # 33206 is equivalent to -rw-rw-rw-
          end
        end
      end

      def initialize(mapped_zip)
        @mapped_zip = mapped_zip
      end

      def get_entry(filename)
        unless exists?(filename)
          raise Errno::ENOENT, "No such file or directory - #{filename}"
        end

        @mapped_zip.find_entry(filename)
      end
      private :get_entry

      def unix_mode_cmp(filename, mode)
        e = get_entry(filename)
        e.fstype == 3 && ((e.external_file_attributes >> 16) & mode) != 0
      rescue Errno::ENOENT
        false
      end
      private :unix_mode_cmp

      def exists?(filename)
        expand_path(filename) == '/' || !@mapped_zip.find_entry(filename).nil?
      end
      alias exist? exists?

      # Permissions not implemented, so if the file exists it is accessible
      alias owned? exists?
      alias grpowned? exists?

      def readable?(filename)
        unix_mode_cmp(filename, 0o444)
      end
      alias readable_real? readable?

      def writable?(filename)
        unix_mode_cmp(filename, 0o222)
      end
      alias writable_real? writable?

      def executable?(filename)
        unix_mode_cmp(filename, 0o111)
      end
      alias executable_real? executable?

      def setuid?(filename)
        unix_mode_cmp(filename, 0o4000)
      end

      def setgid?(filename)
        unix_mode_cmp(filename, 0o2000)
      end

      def sticky?(filename)
        unix_mode_cmp(filename, 0o1000)
      end

      def umask(*args)
        ::File.umask(*args)
      end

      def truncate(_filename, _len)
        raise StandardError, 'truncate not supported'
      end

      def directory?(filename)
        entry = @mapped_zip.find_entry(filename)
        expand_path(filename) == '/' || (!entry.nil? && entry.directory?)
      end

      def open(filename, mode = 'r', permissions = 0o644, &block)
        mode.delete!('b') # ignore b option
        case mode
        when 'r'
          @mapped_zip.get_input_stream(filename, &block)
        when 'w'
          @mapped_zip.get_output_stream(filename, permissions, &block)
        else
          raise StandardError, "openmode '#{mode} not supported" unless mode == 'r'
        end
      end

      def new(filename, mode = 'r')
        self.open(filename, mode)
      end

      def size(filename)
        @mapped_zip.get_entry(filename).size
      end

      # Returns nil for not found and nil for directories
      def size?(filename)
        entry = @mapped_zip.find_entry(filename)
        entry.nil? || entry.directory? ? nil : entry.size
      end

      def chown(owner, group, *filenames)
        filenames.each do |filename|
          e = get_entry(filename)
          e.extra.create('IUnix') unless e.extra.member?('IUnix')
          e.extra['IUnix'].uid = owner
          e.extra['IUnix'].gid = group
        end
        filenames.size
      end

      def chmod(mode, *filenames)
        filenames.each do |filename|
          e = get_entry(filename)
          e.fstype = 3 # force convertion filesystem type to unix
          e.unix_perms = mode
          e.external_file_attributes = mode << 16
          e.dirty = true
        end
        filenames.size
      end

      def zero?(filename)
        sz = size(filename)
        sz.nil? || sz == 0
      rescue Errno::ENOENT
        false
      end

      def file?(filename)
        entry = @mapped_zip.find_entry(filename)
        !entry.nil? && entry.file?
      end

      def dirname(filename)
        ::File.dirname(filename)
      end

      def basename(filename)
        ::File.basename(filename)
      end

      def split(filename)
        ::File.split(filename)
      end

      def join(*fragments)
        ::File.join(*fragments)
      end

      def utime(modified_time, *filenames)
        filenames.each do |filename|
          get_entry(filename).time = modified_time
        end
      end

      def mtime(filename)
        @mapped_zip.get_entry(filename).mtime
      end

      def atime(filename)
        e = get_entry(filename)
        if e.extra.member? 'UniversalTime'
          e.extra['UniversalTime'].atime
        elsif e.extra.member? 'NTFS'
          e.extra['NTFS'].atime
        end
      end

      def ctime(filename)
        e = get_entry(filename)
        if e.extra.member? 'UniversalTime'
          e.extra['UniversalTime'].ctime
        elsif e.extra.member? 'NTFS'
          e.extra['NTFS'].ctime
        end
      end

      def pipe?(_filename)
        false
      end

      def blockdev?(_filename)
        false
      end

      def chardev?(_filename)
        false
      end

      def symlink?(_filename)
        false
      end

      def socket?(_filename)
        false
      end

      def ftype(filename)
        @mapped_zip.get_entry(filename).directory? ? 'directory' : 'file'
      end

      def readlink(_filename)
        raise NotImplementedError, 'The readlink() function is not implemented'
      end

      def symlink(_filename, _symlink_name)
        raise NotImplementedError, 'The symlink() function is not implemented'
      end

      def link(_filename, _symlink_name)
        raise NotImplementedError, 'The link() function is not implemented'
      end

      def pipe
        raise NotImplementedError, 'The pipe() function is not implemented'
      end

      def stat(filename)
        raise Errno::ENOENT, filename unless exists?(filename)

        ZipFsStat.new(self, filename)
      end

      alias lstat stat

      def readlines(filename)
        self.open(filename, &:readlines)
      end

      def read(filename)
        @mapped_zip.read(filename)
      end

      def popen(*args, &a_proc)
        ::File.popen(*args, &a_proc)
      end

      def foreach(filename, sep = $INPUT_RECORD_SEPARATOR, &a_proc)
        self.open(filename) { |is| is.each_line(sep, &a_proc) }
      end

      def delete(*args)
        args.each do |filename|
          if directory?(filename)
            raise Errno::EISDIR, "Is a directory - \"#{filename}\""
          end

          @mapped_zip.remove(filename)
        end
      end

      def rename(file_to_rename, new_name)
        @mapped_zip.rename(file_to_rename, new_name) { true }
      end

      alias unlink delete

      def expand_path(path)
        @mapped_zip.expand_path(path)
      end
    end

    # Instances of this class are normally accessed via the accessor
    # ZipFile::dir. An instance of ZipFsDir behaves like ruby's
    # builtin Dir (class) object, except it works on ZipFile entries.
    #
    # The individual methods are not documented due to their
    # similarity with the methods in Dir
    class ZipFsDir
      def initialize(mapped_zip)
        @mapped_zip = mapped_zip
      end

      attr_writer :file

      def new(directory_name)
        ZipFsDirIterator.new(entries(directory_name))
      end

      def open(directory_name)
        dir_iter = new(directory_name)
        if block_given?
          begin
            yield(dir_iter)
            return nil
          ensure
            dir_iter.close
          end
        end
        dir_iter
      end

      def pwd
        @mapped_zip.pwd
      end
      alias getwd pwd

      def chdir(directory_name)
        unless @file.stat(directory_name).directory?
          raise Errno::EINVAL, "Invalid argument - #{directory_name}"
        end

        @mapped_zip.pwd = @file.expand_path(directory_name)
      end

      def entries(directory_name)
        entries = []
        foreach(directory_name) { |e| entries << e }
        entries
      end

      def glob(*args, &block)
        @mapped_zip.glob(*args, &block)
      end

      def foreach(directory_name)
        unless @file.stat(directory_name).directory?
          raise Errno::ENOTDIR, directory_name
        end

        path = @file.expand_path(directory_name)
        path << '/' unless path.end_with?('/')
        path = Regexp.escape(path)
        subdir_entry_regex = Regexp.new("^#{path}([^/]+)$")
        @mapped_zip.each do |filename|
          match = subdir_entry_regex.match(filename)
          yield(match[1]) unless match.nil?
        end
      end

      def delete(entry_name)
        unless @file.stat(entry_name).directory?
          raise Errno::EINVAL, "Invalid argument - #{entry_name}"
        end

        @mapped_zip.remove(entry_name)
      end
      alias rmdir delete
      alias unlink delete

      def mkdir(entry_name, permissions = 0o755)
        @mapped_zip.mkdir(entry_name, permissions)
      end

      def chroot(*_args)
        raise NotImplementedError, 'The chroot() function is not implemented'
      end
    end

    class ZipFsDirIterator # :nodoc:all
      include Enumerable

      def initialize(filenames)
        @filenames = filenames
        @index = 0
      end

      def close
        @filenames = nil
      end

      def each(&a_proc)
        raise IOError, 'closed directory' if @filenames.nil?

        @filenames.each(&a_proc)
      end

      def read
        raise IOError, 'closed directory' if @filenames.nil?

        @filenames[(@index += 1) - 1]
      end

      def rewind
        raise IOError, 'closed directory' if @filenames.nil?

        @index = 0
      end

      def seek(position)
        raise IOError, 'closed directory' if @filenames.nil?

        @index = position
      end

      def tell
        raise IOError, 'closed directory' if @filenames.nil?

        @index
      end
    end

    # All access to Zip::File from ZipFsFile and ZipFsDir goes through a
    # ZipFileNameMapper, which has one responsibility: ensure
    class ZipFileNameMapper # :nodoc:all
      include Enumerable

      def initialize(zip_file)
        @zip_file = zip_file
        @pwd = '/'
      end

      attr_accessor :pwd

      def find_entry(filename)
        @zip_file.find_entry(expand_to_entry(filename))
      end

      def get_entry(filename)
        @zip_file.get_entry(expand_to_entry(filename))
      end

      def get_input_stream(filename, &a_proc)
        @zip_file.get_input_stream(expand_to_entry(filename), &a_proc)
      end

      def get_output_stream(filename, permissions = nil, &a_proc)
        @zip_file.get_output_stream(
          expand_to_entry(filename), permissions, &a_proc
        )
      end

      def glob(pattern, *flags, &block)
        @zip_file.glob(expand_to_entry(pattern), *flags, &block)
      end

      def read(filename)
        @zip_file.read(expand_to_entry(filename))
      end

      def remove(filename)
        @zip_file.remove(expand_to_entry(filename))
      end

      def rename(filename, new_name, &continue_on_exists_proc)
        @zip_file.rename(
          expand_to_entry(filename),
          expand_to_entry(new_name),
          &continue_on_exists_proc
        )
      end

      def mkdir(filename, permissions = 0o755)
        @zip_file.mkdir(expand_to_entry(filename), permissions)
      end

      # Turns entries into strings and adds leading /
      # and removes trailing slash on directories
      def each
        @zip_file.each do |e|
          yield('/' + e.to_s.chomp('/'))
        end
      end

      def expand_path(path)
        expanded = path.start_with?('/') ? path : ::File.join(@pwd, path)
        expanded.gsub!(/\/\.(\/|$)/, '')
        expanded.gsub!(/[^\/]+\/\.\.(\/|$)/, '')
        expanded.empty? ? '/' : expanded
      end

      private

      def expand_to_entry(path)
        expand_path(path)[1..-1]
      end
    end
  end

  class File
    include FileSystem
  end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
