# frozen_string_literal: true

require 'fiddle'
require 'fiddle/import'

module AmazingPrint
  module Formatters
    module Kernel32
      extend Fiddle::Importer
      dlload 'kernel32'
      extern 'unsigned long GetFileAttributesA(const char*)'
    end

    class GetChildItem
      def initialize(fname)
        @fname = fname
        @stat = File.send(File.symlink?(@fname) ? :lstat : :stat, @fname)
        @attrs = Kernel32::GetFileAttributesA @fname
      end

      # docs.microsoft.com/en-us/windows/win32/fileio/file-attribute-constants
      FILE_ATTRIBUTE_ARCHIVE  = 0x20
      FILE_ATTRIBUTE_READONLY = 0x1
      FILE_ATTRIBUTE_HIDDEN   = 0x2
      FILE_ATTRIBUTE_SYSTEM   = 0x4

      def mode
        r = ['-'] * 6
        r[0] = 'd' if @stat.directory?
        r[1] = 'a' unless (@attrs & FILE_ATTRIBUTE_ARCHIVE).zero?
        r[2] = 'r' unless (@attrs & FILE_ATTRIBUTE_READONLY).zero?
        r[3] = 'h' unless (@attrs & FILE_ATTRIBUTE_HIDDEN).zero?
        r[4] = 's' unless (@attrs & FILE_ATTRIBUTE_SYSTEM).zero?
        r[5] = 'l' if File.symlink? @fname
        r.join
      end

      def last_write_time
        @stat.mtime.strftime '%Y-%m-%d     %H:%M'
      end

      def length
        @stat.file? ? @stat.size.to_s : ''
      end

      def name
        @fname
      end

      def to_s
        format '%-12<Mode>s %<LastWriteTime>s %14<Length>s %<Name>s',
               {
                 Mode: mode,
                 LastWriteTime: last_write_time,
                 Length: length,
                 Name: name
               }
      end
    end
  end
end

puts AmazingPrint::Formatters::GetChildItem.new ARGV[0] if __FILE__ == $PROGRAM_NAME
