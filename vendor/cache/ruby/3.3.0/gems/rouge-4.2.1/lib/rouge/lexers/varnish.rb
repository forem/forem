# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Varnish < RegexLexer
      title 'VCL: Varnish Configuration Language'
      desc 'The configuration language for Varnish HTTP Cache (varnish-cache.org)'

      tag 'vcl'
      aliases 'varnishconf', 'varnish'
      filenames '*.vcl'
      mimetypes 'text/x-varnish', 'text/x-vcl'

      SPACE = '[ \f\n\r\t\v]+'

      # backend acl
      def self.keywords
        @keywords ||= Set.new %w[
          vcl set unset include import if else elseif elif elsif director probe
          backend acl

          declare local
          BOOL FLOAT INTEGER IP RTIME STRING TIME
        ]
      end

      def self.functions
        @functions ||= Set.new %w[
          ban call hash_data new regsub regsuball return rollback
          std.cache_req_body std.collect std.duration std.fileread std.healthy
          std.integer std.ip std.log std.port std.querysort std.random std.real
          std.real2time std.rollback std.set_ip_tos std.strstr std.syslog
          std.time std.time2integer std.time2real std.timestamp std.tolower
          std.toupper synth synthetic
        ]
      end

      def self.variables
        @variables ||= Set.new %w[
          bereq bereq.backend bereq.between_bytes_timeout bereq.connect_timeout
          bereq.first_byte_timeout bereq.method bereq.proto bereq.retries
          bereq.uncacheable bereq.url bereq.xid beresp beresp.age
          beresp.backend beresp.backend.ip beresp.backend.name beresp.do_esi
          beresp.do_gunzip beresp.do_gzip beresp.do_stream beresp.grace
          beresp.keep beresp.proto beresp.reason beresp.status
          beresp.storage_hint beresp.ttl beresp.uncacheable beresp.was_304
          client.identity client.ip local.ip now obj.age obj.grace obj.hits
          obj.keep obj.proto obj.reason obj.status obj.ttl obj.uncacheable
          remote.ip req req.backend_hint req.can_gzip req.esi req.esi_level
          req.hash_always_miss req.hash_ignore_busy req.method req.proto
          req.restarts req.ttl req.url req.xid resp resp.proto resp.reason
          resp.status server.hostname server.identity server.ip
        ]
      end

      # This is never used
      # def self.routines
      #   @routines ||= Set.new %w[
      #     backend_error backend_fetch backend_response purge deliver fini hash
      #     hit init miss pass pipe recv synth
      #   ]
      # end

      state :root do
        # long strings ({" ... "})
        rule %r/\{".*?"}/m, Str::Single

        # heredoc style long strings ({xyz"..."xyz})
        rule %r/\{(\w+)".*?"(\1)\}/m, Str::Single

        # comments
        rule %r'/\*.*?\*/'m, Comment::Multiline
        rule %r'(?://|#).*', Comment::Single

        rule %r/true|false/, Keyword::Constant

        # "wildcard variables"
        var_prefix = Regexp.union(%w(beresp bereq resp req obj))
        rule %r/(?:#{var_prefix})\.http\.[\w.-]+/ do
          token Name::Variable
        end

        # local variables (var.*)
        rule %r/(?:var)\.[\w.-]+/ do
          token Name::Variable
        end

        rule %r/(sub)(#{SPACE})([\w-]+)/ do
          groups Keyword, Text, Name::Function
        end

        # inline C (C{ ... }C)
        rule %r/C\{/ do
          token Comment::Preproc
          push :inline_c
        end

        rule %r/\.?[a-z_][\w.-]*/i do |m|
          next token Keyword if self.class.keywords.include? m[0]
          next token Name::Function if self.class.functions.include? m[0]
          next token Name::Variable if self.class.variables.include? m[0]
          token Text
        end

        ## for number literals

        decimal = %r/[0-9]+/
        hex = %r/[0-9a-f]+/i

        numeric = %r{
          (?:
            0x#{hex}
            (?:\.#{hex})?
            (?:p[+-]?#{hex})?
          )
          |
          (?:
            #{decimal}
            (?:\.#{decimal})?
            (?:e[+-]?#{decimal})?
          )
        }xi

        # duration literals
        duration_suffix = Regexp.union(%w(ms s m h d w y))
        rule %r/#{numeric}#{duration_suffix}/, Num::Other

        # numeric literals (integer / float)
        rule numeric do |m|
            case m[0]
            when /^#{decimal}$/
              token Num::Integer
            when /^0x#{hex}$/
              token Num::Integer
            else
              token Num::Float
            end
        end

        # standard strings
        rule %r/"/, Str::Double, :string

        rule %r'[&|+-]{2}|[<=>!*/+-]=|<<|>>|!~|[-+*/%><=!&|~]', Operator

        rule %r/[{}();.,]/, Punctuation

        rule %r/\r\n?|\n/, Text
        rule %r/./, Text
      end

      state :string do
        rule %r/"/, Str::Double, :pop!
        rule %r/\\[\\"nt]/, Str::Escape

        rule %r/\r\n?|\n/, Str::Double
        rule %r/./, Str::Double
      end

      state :inline_c do
        rule %r/}C/, Comment::Preproc, :pop!
        rule %r/.*?(?=}C)/m do
          delegate C
        end
      end
    end
  end
end
