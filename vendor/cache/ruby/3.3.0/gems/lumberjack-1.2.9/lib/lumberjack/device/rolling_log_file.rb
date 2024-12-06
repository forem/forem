# frozen_string_literals: true

module Lumberjack
  class Device
    # This is an abstract class for a device that appends entries to a file and periodically archives
    # the existing file and starts a one. Subclasses must implement the roll_file? and archive_file_suffix
    # methods.
    #
    # The :keep option can be used to specify a maximum number of rolled log files to keep.
    # Older files will be deleted based on the time they were created. The default is to keep all files.
    #
    # The :min_roll_check option can be used to specify the number of seconds between checking
    # the file to determine if it needs to be rolled. The default is to check at most once per second.
    class RollingLogFile < LogFile
      attr_reader :path
      attr_accessor :keep

      def initialize(path, options = {})
        @path = File.expand_path(path)
        @keep = options[:keep]
        super(path, options)
        @file_inode = begin
          stream.lstat.ino
        rescue
          nil
        end
        @@rolls = []
        @next_stat_check = Time.now.to_f
        @min_roll_check = (options[:min_roll_check] || 1.0).to_f
      end

      # Returns a suffix that will be appended to the file name when it is archived.. The suffix should
      # change after it is time to roll the file. The log file will be renamed when it is rolled.
      def archive_file_suffix
        raise NotImplementedError
      end

      # Return +true+ if the file should be rolled.
      def roll_file?
        raise NotImplementedError
      end

      # Roll the log file by renaming it to the archive file name and then re-opening a stream to the log
      # file path. Rolling a file is safe in multi-threaded or multi-process environments.
      def roll_file! # :nodoc:
        do_once(stream) do
          archive_file = "#{path}.#{archive_file_suffix}"
          stream.flush
          current_inode = begin
            File.stat(path).ino
          rescue
            nil
          end
          if @file_inode && current_inode == @file_inode && !File.exist?(archive_file) && File.exist?(path)
            begin
              File.rename(path, archive_file)
              after_roll
              cleanup_files!
            rescue SystemCallError
              # Ignore rename errors since it indicates the file was already rolled
            end
          end
          reopen_file
        end
      rescue => e
        $stderr.write("Failed to roll file #{path}: #{e.inspect}\n#{e.backtrace.join("\n")}\n")
      end

      protected

      # This method will be called after a file has been rolled. Subclasses can
      # implement code to reset the state of the device. This method is thread safe.
      def after_roll
      end

      # Handle rolling the file before flushing.
      def before_flush # :nodoc:
        if @min_roll_check <= 0.0 || Time.now.to_f >= @next_stat_check
          @next_stat_check += @min_roll_check
          path_inode = begin
            File.lstat(path).ino
          rescue
            nil
          end
          if path_inode != @file_inode
            @file_inode = path_inode
            reopen_file
          elsif roll_file?
            roll_file!
          end
        end
      end

      private

      def reopen_file
        old_stream = stream
        new_stream = File.open(path, "a", encoding: EXTERNAL_ENCODING)
        new_stream.sync = true if buffer_size > 0
        @file_inode = begin
          new_stream.lstat.ino
        rescue
          nil
        end
        self.stream = new_stream
        old_stream.close
      end
    end

    def cleanup_files!
      if keep
        files = Dir.glob("#{path}.*").collect { |f| [f, File.ctime(f)] }.sort { |a, b| b.last <=> a.last }.collect { |a| a.first }
        if files.size > keep
          files[keep, files.length].each do |f|
            File.delete(f)
          end
        end
      end
    end

    def do_once(file)
      begin
        file.flock(File::LOCK_EX)
      rescue SystemCallError
        # Most likely can't lock file because the stream is closed
        return
      end
      begin
        verify = begin
          file.lstat
        rescue
          nil
        end
        # Execute only if the file we locked is still the same one that needed to be rolled
        yield if verify && verify.ino == @file_inode && verify.size > 0
      ensure
        begin
          file.flock(File::LOCK_UN)
        rescue
          nil
        end
      end
    end
  end
end
