require "guard/config"

if Guard::Config.new.strict?
  abort "Error: Deprecated file #{__FILE__} is being used"
else
  require "guard/deprecated/guardfile"

  # TODO: remove this file in next major version

  module Guard
    unless Guard::Config.new.silence_deprecations?
      UPGRADE_WIKI_URL =
        "https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0"

      STDERR.puts <<-EOS
        (guard/guardfile.rb message)

        You are including "guard/guardfile.rb", which has been deprecated
        since 2013 ... and will be removed.

        Migration is easy, see: #{UPGRADE_WIKI_URL}

        This file was included from:
          #{caller[0..10] * "\n  >"}

        Sorry for the inconvenience and have a nice day!

        (end of guard/guardfile.rb message)


      EOS
    end
    module Guardfile
      extend Deprecated::Guardfile::ClassMethods
    end
  end
end
