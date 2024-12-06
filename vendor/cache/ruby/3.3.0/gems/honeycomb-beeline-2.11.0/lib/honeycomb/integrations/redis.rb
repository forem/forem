# frozen_string_literal: true

require "redis"

module Honeycomb
  module Redis
    # Patches Redis with the option to configure the Honeycomb client.
    #
    # When you load this integration, each Redis call will be wrapped in a span
    # containing information about the command being invoked.
    #
    # This module automatically gets mixed into the Redis class so you can
    # change the underlying {Honeycomb::Client}. By default, we use the global
    # {Honeycomb.client} to send events. A nil client will disable the
    # integration altogether.
    #
    # @example Custom client
    #   Redis.honeycomb_client = Honeycomb::Client.new(...)
    #
    # @example Disabling instrumentation
    #   Redis.honeycomb_client = nil
    module Configuration
      attr_writer :honeycomb_client

      def honeycomb_client
        return @honeycomb_client if defined?(@honeycomb_client)

        Honeycomb.client
      end
    end

    # Patches Redis::Client with Honeycomb instrumentation.
    #
    # Circa versions 3.x and 4.x of their gem, the Redis class is backed by an
    # underlying Redis::Client object. The methods used to send commands to the
    # Redis server - namely Redis::Client#call, Redis::Client#call_loop,
    # Redis::Client#call_pipeline, Redis::Client#call_pipelined,
    # Redis::Client#call_with_timeout, and Redis::Client#call_without_timeout -
    # all eventually wind up calling the Redis::Client#process method to do the
    # "dirty work" of writing commands out to an underlying connection. So this
    # gives us a single point of entry that's ideal for introducing the
    # Honeycomb span.
    #
    # An alternative interface provided since at least version 3.0.0 is
    # Redis::Distributed. Underneath, though, it maintains a collection of
    # Redis objects, and each call is forwarded to one or more members of the
    # collection. So patching Redis::Client still captures spans originating
    # from Redis::Distributed. Typical commands (i.e., ones that aren't
    # "global" like `QUIT` or `FLUSHALL`) forward to just a single node anyway,
    # so there's not much use to wrapping everything up in a span for the
    # Redis::Distributed method call.
    #
    # Another alternative interface provided since v4.0.3 is Redis::Cluster,
    # which you can configure the Redis class to use instead of Redis::Client.
    # Again, though, Redis::Cluster maintains a collection of Redis::Client
    # instances underneath. The tracing needs wind up being pretty much the
    # same as Redis::Distributed, even though the actual architecture is
    # significantly different.
    #
    # An implementation detail of pub/sub commands since v2.0.0 (well below our
    # supported version of the redis gem!) is Redis::SubscribedClient, but that
    # still wraps an underlying Redis::Client or Redis::Cluster instance.
    #
    # @see https://github.com/redis/redis-rb/blob/2e8577ad71d0efc32f31fb034f341e1eb10abc18/lib/redis/client.rb#L77-L180
    #   Relevant Redis::Client methods circa v3.0.0
    # @see https://github.com/redis/redis-rb/blob/a2c562c002bc8f86d1f47818d63db2da1c5c3d3f/lib/redis/client.rb#L124-L239
    #   Relevant Redis::Client methods circa v4.1.3
    # @see https://github.com/redis/redis-rb/commits/master/lib/redis/client.rb
    #   History of Redis::Client
    #
    # @see https://redis.io/topics/partitioning
    #   Partitioning (the basis for Redis::Distributed)
    # @see https://github.com/redis/redis-rb/blob/2e8577ad71d0efc32f31fb034f341e1eb10abc18/lib/redis/distributed.rb
    #   Redis::Distributed circa v3.0.0
    # @see https://github.com/redis/redis-rb/blob/a2c562c002bc8f86d1f47818d63db2da1c5c3d3f/lib/redis/distributed.rb
    #   Redis::Distributed circa v4.1.3
    # @see https://github.com/redis/redis-rb/commits/master/lib/redis/distributed.rb
    #   History of Redis::Distributed
    #
    # @see https://redis.io/topics/cluster-spec
    #   Clustering (the basis for Redis::Cluster)
    # @see https://github.com/redis/redis-rb/commit/7f48c0b02fa89256167bc481a73ce2e0c8cca89a
    #   Initial implementation of Redis::Cluster released in v4.0.3
    # @see https://github.com/redis/redis-rb/blob/a2c562c002bc8f86d1f47818d63db2da1c5c3d3f/lib/redis/cluster.rb
    #   Redis::Cluster circa v4.1.3
    # @see https://github.com/redis/redis-rb/commits/master/lib/redis/cluster.rb
    #   History of Redis::Cluster
    #
    # @see https://redis.io/topics/pubsub
    #   Pub/Sub in Redis
    # @see https://github.com/redis/redis-rb/blob/17d40d80388b536ec53a8f19bb1404e93a61650f/lib/redis/subscribe.rb
    #   Redis::SubscribedClient circa v2.0.0
    # @see https://github.com/redis/redis-rb/blob/2e8577ad71d0efc32f31fb034f341e1eb10abc18/lib/redis/subscribe.rb
    #   Redis::SubscribedClient circa v3.0.0
    # @see https://github.com/redis/redis-rb/blob/a2c562c002bc8f86d1f47818d63db2da1c5c3d3f/lib/redis/subscribe.rb
    #   Redis::SubscribedClient circa v4.1.3
    module Client
      def process(commands)
        return super if ::Redis.honeycomb_client.nil?

        span = ::Redis.honeycomb_client.start_span(name: "redis")
        begin
          fields = Fields.new(self)
          fields.options = @options
          fields.command = commands
          span.add fields
          super
        rescue StandardError => e
          span.add_field "redis.error", e.class.name
          span.add_field "redis.error_detail", e.message
          raise
        ensure
          span.send
        end
      end
    end

    # This structure contains the fields we'll add to each Redis span.
    #
    # The logic is in this class to avoid monkey-patching extraneous APIs into
    # the Redis::Client via {Client}.
    #
    # @private
    class Fields
      def initialize(client)
        @client = client
      end

      def options=(options)
        options.each do |option, value|
          values["redis.#{option}"] ||= value unless ignore?(option)
        end
      end

      def command=(commands)
        commands = Array(commands)
        values["redis.command"] = commands.map { |cmd| format(cmd) }.join("\n")
      end

      def to_hash
        values
      end

      private

      def values
        @values ||= {
          "meta.package" => "redis",
          "meta.package_version" => ::Redis::VERSION,
          "redis.id" => @client.id,
          "redis.location" => @client.location,
        }
      end

      # Do we ignore this Redis::Client option?
      #
      # * :url - unsafe because it might contain a password
      # * :password - unsafe
      # * :logger - just some Ruby object, not useful
      # * :_parsed - implementation detail
      def ignore?(option)
        # Redis options may be symbol or string keys.
        #
        # This normalizes `option` using `to_sym` as benchmarking on Ruby MRI
        # v2.6.6 and v2.7.3 has shown that was faster compared to `to_s`.
        # However, `nil` does not support `to_sym`. This uses a guard clause to
        # handle the `nil` case because this is still faster than safe
        # navigation. Also this lib still supports Ruby 2.2.0; which does not
        # include safe navigation.
        return true unless option

        %i[url password logger _parsed].include?(option.to_sym)
      end

      def format(cmd)
        name, *args = cmd.flatten(1)
        name = resolve(name)
        sanitize(args) if name.casecmp("auth").zero?
        [name.upcase, *args.map { |arg| prettify(arg) }].join(" ")
      end

      def resolve(name)
        @client.command_map.fetch(name, name).to_s
      end

      def sanitize(args)
        args.map! { "[sanitized]" }
      end

      # This aims to replicate the algorithms used by redis-cli.
      #
      # @see https://github.com/antirez/redis/blob/0f026af185e918a9773148f6ceaa1b084662be88/src/sds.c#L940-L1067
      #   The redis-cli parsing algorithm
      #
      # @see https://github.com/antirez/redis/blob/0f026af185e918a9773148f6ceaa1b084662be88/src/sds.c#L878-L907
      #   The redis-cli printing algorithm
      def prettify(arg)
        pretty = arg.to_s.dup
        pretty.encode!("UTF-8", "binary", fallback: ->(c) { hex(c) })
        pretty.gsub!(NEEDS_BACKSLASH, BACKSLASH)
        pretty.gsub!(NEEDS_HEX) { |c| hex(c) }
        pretty =~ NEEDS_QUOTES ? "\"#{pretty}\"" : pretty
      end

      # A regular expression matching characters that need to be hex-encoded.
      #
      # This replicates the C isprint() function that redis-cli uses to decide
      # whether to escape a character in hexadecimal notation, "\xhh". Any
      # non-printable character must be represented as a hex escape sequence.
      #
      # Normally, we could match this using a negated POSIX bracket expression:
      #
      #   /[^[:print:]]/
      #
      # You can read that as "not printable".
      #
      # However, in Ruby, these character classes also encompass non-ASCII
      # characters. In contrast, since most platforms have 8-bit `char` types,
      # the C isprint() function generally does not recognize any Unicode code
      # points. This effectively limits the redis-cli interpretation of the
      # printable character range to just printable ASCII characters.
      #
      # Thus, we match using a combination of the previous regexp with a
      # non-POSIX character class that Ruby defines:
      #
      #   /[^[:print:]&&[:ascii:]]/
      #
      # You can read this like
      #
      #   NOT (printable AND ascii)
      #
      # which by DeMorgan's Law is equivalent to
      #
      #   (NOT printable) OR (NOT ascii)
      #
      # That is, if the character is not printable (even in Unicode), we'll
      # escape it; if the character is printable but non-ASCII, we'll also
      # escape it.
      #
      # What's more, Ruby's Regexp#=~ method will blow up if the string does
      # not have a valid encoding (e.g., in UTF-8). We handle this case
      # separately, though, using String#encode! with a :fallback option to
      # hex-encode invalid UTF-8 byte sequences with {#hex}.
      #
      # @see https://ruby-doc.org/core-2.6.5/Regexp.html
      # @see https://github.com/antirez/redis/blob/0f026af185e918a9773148f6ceaa1b084662be88/src/sds.c#L878-L880
      # @see https://github.com/antirez/redis/blob/0f026af185e918a9773148f6ceaa1b084662be88/src/sds.c#L898-L901
      # @see https://www.justinweiss.com/articles/3-steps-to-fix-encoding-problems-in-ruby/
      NEEDS_HEX = /[^[:print:]&&[:ascii:]]/.freeze

      # A regular expression for characters that need to be backslash-escaped.
      #
      # Any match of this regexp will be substituted according to the
      # {BACKSLASH} table. This includes standard C escape sequences (newlines,
      # tabs, etc) as well as a couple special considerations:
      #
      # 1. Because {#prettify} will output double quoted strings if any
      #    escaping is needed, we must match double quotes (") so they'll be
      #    replaced by escaped quotes (\").
      #
      # 2. Backslashes themselves get backslash-escaped, so \ becomes \\.
      #    However, strings with invalid UTF-8 encoding will blow up when we
      #    try to use String#gsub!, so {#prettify} must first use
      #    String#encode! to scrub out invalid characters. It does this by
      #    replacing invalid bytes with hex-encoded escape sequences using
      #    {#hex}. This will insert sequences like \xhh, which contains a
      #    backslash that we *don't* want to escape.
      #
      #    Unfortunately, this regexp can't really distinguish between
      #    backslashes in the original input vs backslashes resulting from the
      #    UTF-8 fallback. We make an effort by using a negative lookahead.
      #    That way, only backslashes that *aren't* followed by x + hex digit +
      #    hex digit will be escaped.
      NEEDS_BACKSLASH = /["\n\r\t\a\b]|\\(?!x\h\h)/.freeze

      # A lookup table for backslash-escaped characters.
      #
      # This is used by {#prettify} to replicate the hard-coded `case`
      # statements in redis-cli. As of this writing, Redis recognizes a handful
      # of standard C escape sequences, like "\n" for newlines.
      #
      # Because {#prettify} will output double quoted strings if any escaping
      # is needed, this table must additionally consider the double-quote to be
      # a backslash-escaped character. For example, instead of generating
      #
      #   '"hello"'
      #
      # we'll generate
      #
      #   "\"hello\""
      #
      # even though redis-cli would technically recognize the single-quoted
      # version.
      #
      # @see https://github.com/antirez/redis/blob/0f026af185e918a9773148f6ceaa1b084662be88/src/sds.c#L888-L896
      #   The redis-cli algorithm for outputting standard escape sequences
      BACKSLASH = {
        "\\" => "\\\\",
        '"' => '\\"',
        "\n" => "\\n",
        "\r" => "\\r",
        "\t" => "\\t",
        "\a" => "\\a",
        "\b" => "\\b",
      }.freeze

      # If the final escaped string needs quotes, it will match this regexp.
      #
      # The overall string returned by {#prettify} should only be quoted if at
      # least one of the following holds:
      #
      # 1. The string contains an escape sequence, broadly demarcated by a
      #    backslash. This includes standard escape sequences like "\n" and
      #    "\t" as well as hex-encoded bytes using the "\x" escape sequence.
      #    Since {#prettify} uses double quotes on its output string, we must
      #    also force quotes if the string itself contains a literal
      #    double quote. This double quote behavior is handled tacitly by the
      #    {NEEDS_BACKSLASH} + {BACKSLASH} replacement.
      #
      # 2. The string contains a single quote. Since redis-cli recognizes
      #    single-quoted strings, we want to wrap the {#prettify} output in
      #    double quotes so that the literal single quote character isn't
      #    mistaken as the delimiter of a new string.
      #
      # 3. The string contains any whitespace characters. If the {#prettify}
      #    output weren't wrapped in quotes, whitespace would act as a
      #    separator between arguments to the Redis command. To group things
      #    together, we need to quote the string.
      NEEDS_QUOTES = /[\\'\s]/.freeze

      # Hex-encodes a (presumably non-printable or non-ASCII) character.
      #
      # Aside from standard backslash escape sequences, redis-cli also
      # recognizes "\xhh" notation, where `hh` is a hexadecimal number.
      #
      # Of note is that redis-cli only recognizes *exactly* two-digit
      # hexadecimal numbers. This is in accordance with IEEE Std 1003.1-2001,
      # Chapter 7, Locale:
      #
      # > A character can be represented as a hexadecimal constant. A
      # > hexadecimal constant shall be specified as the escape character
      # > followed by an 'x' followed by two hexadecimal digits. Each constant
      # > shall represent a byte value. Multi-byte values can be represented by
      # > concatenated constants specified in byte order with the last constant
      # > specifying the least significant byte of the character.
      #
      # Unlike the C `char` type, Ruby's conception of a character can span
      # multiple bytes (and possibly bytes that aren't valid in Ruby's string
      # encoding). So we take care to escape the input properly into the
      # redis-cli compatible version by iterating through each byte and
      # formatting it as a (zero-padded) 2-digit hexadecimal number prefixed by
      # `\x`.
      #
      # @see https://pubs.opengroup.org/onlinepubs/009695399/basedefs/xbd_chap07.html
      # @see https://github.com/antirez/redis/blob/0f026af185e918a9773148f6ceaa1b084662be88/src/sds.c#L878-L880
      # @see https://github.com/antirez/redis/blob/0f026af185e918a9773148f6ceaa1b084662be88/src/sds.c#L898-L901
      def hex(char)
        char.bytes.map { |b| Kernel.format("\\x%02x", b) }.join
      end
    end
  end
end

Redis.extend(Honeycomb::Redis::Configuration)
Redis::Client.prepend(Honeycomb::Redis::Client)
