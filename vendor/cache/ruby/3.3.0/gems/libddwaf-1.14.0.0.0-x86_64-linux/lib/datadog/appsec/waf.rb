require 'ffi'
require 'json'
require 'datadog/appsec/waf/version'

module Datadog
  module AppSec
    # rubocop:disable Metrics/ModuleLength
    module WAF
      module LibDDWAF
        class Error < StandardError
          attr_reader :diagnostics

          def initialize(msg, diagnostics: nil)
            @diagnostics = diagnostics
          end
        end

        extend ::FFI::Library

        def self.local_os
          if RUBY_ENGINE == 'jruby'
            os_name = java.lang.System.get_property('os.name')

            os = case os_name
                 when /linux/i then 'linux'
                 when /mac/i   then 'darwin'
                 else raise Error, "unsupported JRuby os.name: #{os_name.inspect}"
                 end

            return os
          end

          Gem::Platform.local.os
        end

        def self.local_version
          return nil unless local_os == 'linux'

          # Old rubygems don't handle non-gnu linux correctly
          return $1 if RUBY_PLATFORM =~ /linux-(.+)$/

          'gnu'
        end

        def self.local_cpu
          if RUBY_ENGINE == 'jruby'
            os_arch = java.lang.System.get_property('os.arch')

            cpu = case os_arch
                  when 'amd64' then 'x86_64'
                  when 'aarch64' then 'aarch64'
                  else raise Error, "unsupported JRuby os.arch: #{os_arch.inspect}"
                  end

            return cpu
          end

          Gem::Platform.local.cpu
        end

        def self.source_dir
          __dir__ || raise('__dir__ is nil: eval?')
        end

        def self.vendor_dir
          File.join(source_dir, '../../../vendor')
        end

        def self.libddwaf_vendor_dir
          File.join(vendor_dir, 'libddwaf')
        end

        def self.shared_lib_triplet(version: local_version)
          version ? "#{local_os}-#{version}-#{local_cpu}" : "#{local_os}-#{local_cpu}"
        end

        def self.libddwaf_dir
          default = File.join(libddwaf_vendor_dir,
                              "libddwaf-#{Datadog::AppSec::WAF::VERSION::BASE_STRING}-#{shared_lib_triplet}")
          candidates = [
            default
          ]

          if local_os == 'linux'
            candidates << File.join(libddwaf_vendor_dir,
                                    "libddwaf-#{Datadog::AppSec::WAF::VERSION::BASE_STRING}-#{shared_lib_triplet(version: nil)}")
          end

          candidates.find { |d| Dir.exist?(d) } || default
        end

        def self.shared_lib_extname
          Gem::Platform.local.os == 'darwin' ? '.dylib' : '.so'
        end

        def self.shared_lib_path
          File.join(libddwaf_dir, 'lib', "libddwaf#{shared_lib_extname}")
        end

        ffi_lib [shared_lib_path]

        # version

        attach_function :ddwaf_get_version, [], :string

        # ddwaf::object data structure

        DDWAF_OBJ_TYPE = enum :ddwaf_obj_invalid,  0,
                              :ddwaf_obj_signed,   1 << 0,
                              :ddwaf_obj_unsigned, 1 << 1,
                              :ddwaf_obj_string,   1 << 2,
                              :ddwaf_obj_array,    1 << 3,
                              :ddwaf_obj_map,      1 << 4,
                              :ddwaf_obj_bool,     1 << 5,
                              :ddwaf_obj_float,    1 << 6,
                              :ddwaf_obj_null,     1 << 7

        typedef DDWAF_OBJ_TYPE, :ddwaf_obj_type

        typedef :pointer, :charptr
        typedef :pointer, :charptrptr

        class UInt32Ptr < ::FFI::Struct
          layout :value, :uint32
        end

        typedef UInt32Ptr.by_ref, :uint32ptr

        class UInt64Ptr < ::FFI::Struct
          layout :value, :uint64
        end

        typedef UInt64Ptr.by_ref, :uint64ptr

        class SizeTPtr < ::FFI::Struct
          layout :value, :size_t
        end

        typedef SizeTPtr.by_ref, :sizeptr

        class ObjectValueUnion < ::FFI::Union
          layout :stringValue, :charptr,
                 :uintValue,   :uint64,
                 :intValue,    :int64,
                 :array,       :pointer,
                 :boolean,     :bool,
                 :f64,         :double
        end

        class Object < ::FFI::Struct
          layout :parameterName,       :charptr,
                 :parameterNameLength, :uint64,
                 :valueUnion,          ObjectValueUnion,
                 :nbEntries,           :uint64,
                 :type,                :ddwaf_obj_type
        end

        typedef Object.by_ref, :ddwaf_object

        ## setters

        attach_function :ddwaf_object_invalid, [:ddwaf_object], :ddwaf_object
        attach_function :ddwaf_object_string, [:ddwaf_object, :string], :ddwaf_object
        attach_function :ddwaf_object_stringl, [:ddwaf_object, :charptr, :size_t], :ddwaf_object
        attach_function :ddwaf_object_stringl_nc, [:ddwaf_object, :charptr, :size_t], :ddwaf_object
        attach_function :ddwaf_object_string_from_unsigned, [:ddwaf_object, :uint64], :ddwaf_object
        attach_function :ddwaf_object_string_from_signed, [:ddwaf_object, :int64], :ddwaf_object
        attach_function :ddwaf_object_unsigned, [:ddwaf_object, :uint64], :ddwaf_object
        attach_function :ddwaf_object_signed, [:ddwaf_object, :int64], :ddwaf_object
        attach_function :ddwaf_object_bool, [:ddwaf_object, :bool], :ddwaf_object
        attach_function :ddwaf_object_null, [:ddwaf_object], :ddwaf_object
        attach_function :ddwaf_object_float, [:ddwaf_object, :double], :ddwaf_object

        attach_function :ddwaf_object_array, [:ddwaf_object], :ddwaf_object
        attach_function :ddwaf_object_array_add, [:ddwaf_object, :ddwaf_object], :bool

        attach_function :ddwaf_object_map, [:ddwaf_object], :ddwaf_object
        attach_function :ddwaf_object_map_add, [:ddwaf_object, :string, :pointer], :bool
        attach_function :ddwaf_object_map_addl, [:ddwaf_object, :charptr, :size_t, :pointer], :bool
        attach_function :ddwaf_object_map_addl_nc, [:ddwaf_object, :charptr, :size_t, :pointer], :bool

        ## getters

        attach_function :ddwaf_object_type, [:ddwaf_object], DDWAF_OBJ_TYPE
        attach_function :ddwaf_object_size, [:ddwaf_object], :uint64
        attach_function :ddwaf_object_length, [:ddwaf_object], :size_t
        attach_function :ddwaf_object_get_key, [:ddwaf_object, :sizeptr], :charptr
        attach_function :ddwaf_object_get_string, [:ddwaf_object, :sizeptr], :charptr
        attach_function :ddwaf_object_get_unsigned, [:ddwaf_object], :uint64
        attach_function :ddwaf_object_get_signed, [:ddwaf_object], :int64
        attach_function :ddwaf_object_get_index, [:ddwaf_object, :size_t], :ddwaf_object
        attach_function :ddwaf_object_get_bool, [:ddwaf_object], :bool
        attach_function :ddwaf_object_get_float, [:ddwaf_object], :double

        ## freeers

        ObjectFree = attach_function :ddwaf_object_free, [:ddwaf_object], :void
        ObjectNoFree = ::FFI::Pointer::NULL

        # main handle

        typedef :pointer, :ddwaf_handle
        typedef Object.by_ref, :ddwaf_rule

        callback :ddwaf_object_free_fn, [:ddwaf_object], :void

        class Config < ::FFI::Struct
          class Limits < ::FFI::Struct
            layout :max_container_size,  :uint32,
                   :max_container_depth, :uint32,
                   :max_string_length,   :uint32
          end

          class Obfuscator < ::FFI::Struct
            layout :key_regex,   :pointer, # should be :charptr
                   :value_regex, :pointer  # should be :charptr
          end

          layout :limits,     Limits,
                 :obfuscator, Obfuscator,
                 :free_fn,    :pointer #:ddwaf_object_free_fn
        end

        typedef Config.by_ref, :ddwaf_config

        attach_function :ddwaf_init, [:ddwaf_rule, :ddwaf_config, :ddwaf_object], :ddwaf_handle
        attach_function :ddwaf_update, [:ddwaf_handle, :ddwaf_object, :ddwaf_object], :ddwaf_handle
        attach_function :ddwaf_destroy, [:ddwaf_handle], :void

        attach_function :ddwaf_required_addresses, [:ddwaf_handle, UInt32Ptr], :charptrptr

        # updating

        DDWAF_RET_CODE = enum :ddwaf_err_internal,         -3,
                              :ddwaf_err_invalid_object,   -2,
                              :ddwaf_err_invalid_argument, -1,
                              :ddwaf_ok,                    0,
                              :ddwaf_match,                 1
        typedef DDWAF_RET_CODE, :ddwaf_ret_code

        # running

        typedef :pointer, :ddwaf_context

        attach_function :ddwaf_context_init, [:ddwaf_handle], :ddwaf_context
        attach_function :ddwaf_context_destroy, [:ddwaf_context], :void

        class Result < ::FFI::Struct
          layout :timeout,       :bool,
                 :events,        Object,
                 :actions,       Object,
                 :derivatives,   Object,
                 :total_runtime, :uint64
        end

        typedef Result.by_ref, :ddwaf_result
        typedef :uint64, :timeout_us

        attach_function :ddwaf_run, [:ddwaf_context, :ddwaf_object, :ddwaf_result, :timeout_us], :ddwaf_ret_code, blocking: true
        attach_function :ddwaf_result_free, [:ddwaf_result], :void

        # logging

        DDWAF_LOG_LEVEL = enum :ddwaf_log_trace,
                               :ddwaf_log_debug,
                               :ddwaf_log_info,
                               :ddwaf_log_warn,
                               :ddwaf_log_error,
                               :ddwaf_log_off
        typedef DDWAF_LOG_LEVEL, :ddwaf_log_level

        callback :ddwaf_log_cb, [:ddwaf_log_level, :string, :string, :uint, :charptr, :uint64], :void

        attach_function :ddwaf_set_log_cb, [:ddwaf_log_cb, :ddwaf_log_level], :bool

        DEFAULT_MAX_CONTAINER_SIZE  = 256
        DEFAULT_MAX_CONTAINER_DEPTH = 20
        DEFAULT_MAX_STRING_LENGTH   = 16_384 # in bytes, UTF-8 worst case being 4x size in terms of code point)

        DDWAF_MAX_CONTAINER_SIZE  = 256
        DDWAF_MAX_CONTAINER_DEPTH = 20
        DDWAF_MAX_STRING_LENGTH   = 4096

        DDWAF_RUN_TIMEOUT = 5000
      end

      def self.version
        LibDDWAF.ddwaf_get_version
      end

      # rubocop:disable Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      def self.ruby_to_object(val, max_container_size: nil, max_container_depth: nil, max_string_length: nil, coerce: true)
        case val
        when Array
          obj = LibDDWAF::Object.new
          res = LibDDWAF.ddwaf_object_array(obj)
          if res.null?
            fail LibDDWAF::Error, "Could not convert into object: #{val}"
          end

          max_index = max_container_size - 1 if max_container_size
          val.each.with_index do |e, i|
            member = ruby_to_object(e,
                                    max_container_size: max_container_size,
                                    max_container_depth: (max_container_depth - 1 if max_container_depth),
                                    max_string_length: max_string_length,
                                    coerce: coerce)
            e_res = LibDDWAF.ddwaf_object_array_add(obj, member)
            unless e_res
              fail LibDDWAF::Error, "Could not add to array object: #{e.inspect}"
            end

            break val if max_index && i >= max_index
          end unless max_container_depth == 0

          obj
        when Hash
          obj = LibDDWAF::Object.new
          res = LibDDWAF.ddwaf_object_map(obj)
          if res.null?
            fail LibDDWAF::Error, "Could not convert into object: #{val}"
          end

          max_index = max_container_size - 1 if max_container_size
          val.each.with_index do |e, i|
            k, v = e[0], e[1] # for Steep, which doesn't handle |(k, v), i|

            k = k.to_s[0, max_string_length] if max_string_length
            member = ruby_to_object(v,
                                    max_container_size: max_container_size,
                                    max_container_depth: (max_container_depth - 1 if max_container_depth),
                                    max_string_length: max_string_length,
                                    coerce: coerce)
            kv_res = LibDDWAF.ddwaf_object_map_addl(obj, k.to_s, k.to_s.bytesize, member)
            unless kv_res
              fail LibDDWAF::Error, "Could not add to map object: #{k.inspect} => #{v.inspect}"
            end

            break val if max_index && i >= max_index
          end unless max_container_depth == 0

          obj
        when String
          obj = LibDDWAF::Object.new
          encoded_val = val.to_s.encode('utf-8', invalid: :replace, undef: :replace)
          val = encoded_val[0, max_string_length] if max_string_length
          str = val.to_s
          res = LibDDWAF.ddwaf_object_stringl(obj, str, str.bytesize)
          if res.null?
            fail LibDDWAF::Error, "Could not convert into object: #{val.inspect}"
          end

          obj
        when Symbol
          obj = LibDDWAF::Object.new
          val = val.to_s[0, max_string_length] if max_string_length
          str = val.to_s
          res = LibDDWAF.ddwaf_object_stringl(obj, str, str.bytesize)
          if res.null?
            fail LibDDWAF::Error, "Could not convert into object: #{val.inspect}"
          end

          obj
        when Integer
          obj = LibDDWAF::Object.new
          res = if coerce
                  LibDDWAF.ddwaf_object_string(obj, val.to_s)
                elsif val < 0
                  LibDDWAF.ddwaf_object_signed(obj, val)
                else
                  LibDDWAF.ddwaf_object_unsigned(obj, val)
                end
          if res.null?
            fail LibDDWAF::Error, "Could not convert into object: #{val.inspect}"
          end

          obj
        when Float
          obj = LibDDWAF::Object.new
          res = if coerce
                  LibDDWAF.ddwaf_object_string(obj, val.to_s)
                else
                  LibDDWAF.ddwaf_object_float(obj, val)
                end
          if res.null?
            fail LibDDWAF::Error, "Could not convert into object: #{val.inspect}"
          end

          obj
        when TrueClass, FalseClass
          obj = LibDDWAF::Object.new
          res = if coerce
                  LibDDWAF.ddwaf_object_string(obj, val.to_s)
                else
                  LibDDWAF.ddwaf_object_bool(obj, val)
                end
          if res.null?
            fail LibDDWAF::Error, "Could not convert into object: #{val.inspect}"
          end

          obj
        when NilClass
          obj = LibDDWAF::Object.new
          res = if coerce
                  LibDDWAF.ddwaf_object_string(obj, '')
                else
                  LibDDWAF.ddwaf_object_null(obj)
                end
          if res.null?
            fail LibDDWAF::Error, "Could not convert into object: #{val.inspect}"
          end

          obj
        else
          ruby_to_object(''.freeze)
        end
      end
      # rubocop:enable Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity

      def self.object_to_ruby(obj)
        case obj[:type]
        when :ddwaf_obj_invalid, :ddwaf_obj_null
          nil
        when :ddwaf_obj_bool
          obj[:valueUnion][:boolean]
        when :ddwaf_obj_string
          obj[:valueUnion][:stringValue].read_bytes(obj[:nbEntries])
        when :ddwaf_obj_signed
          obj[:valueUnion][:intValue]
        when :ddwaf_obj_unsigned
          obj[:valueUnion][:uintValue]
        when :ddwaf_obj_float
          obj[:valueUnion][:f64]
        when :ddwaf_obj_array
          (0...obj[:nbEntries]).each.with_object([]) do |i, a|
            ptr = obj[:valueUnion][:array] + i * LibDDWAF::Object.size
            e = object_to_ruby(LibDDWAF::Object.new(ptr))
            a << e
          end
        when :ddwaf_obj_map
          (0...obj[:nbEntries]).each.with_object({}) do |i, h|
            ptr = obj[:valueUnion][:array] + i * Datadog::AppSec::WAF::LibDDWAF::Object.size
            o = Datadog::AppSec::WAF::LibDDWAF::Object.new(ptr)
            l = o[:parameterNameLength]
            k = o[:parameterName].read_bytes(l)
            v = object_to_ruby(LibDDWAF::Object.new(ptr))
            h[k] = v
          end
        end
      end

      def self.log_callback(level, func, file, line, message, len)
        return if logger.nil?

        logger.debug do
          {
            level: level,
            func: func,
            file: file,
            line: line,
            message: message.read_bytes(len)
          }.inspect
        end
      end

      def self.logger
        @logger
      end

      def self.logger=(logger)
        unless @log_callback
          log_callback = method(:log_callback)
          Datadog::AppSec::WAF::LibDDWAF.ddwaf_set_log_cb(log_callback, :ddwaf_log_trace)

          # retain logging proc if set properly
          @log_callback = log_callback
        end

        @logger = logger
      end

      RESULT_CODE = {
        ddwaf_err_internal:         :err_internal,
        ddwaf_err_invalid_object:   :err_invalid_object,
        ddwaf_err_invalid_argument: :err_invalid_argument,
        ddwaf_ok:                   :ok,
        ddwaf_match:                :match,
      }

      class Handle
        attr_reader :handle_obj, :diagnostics, :config

        def initialize(rule, limits: {}, obfuscator: {})
          rule_obj = Datadog::AppSec::WAF.ruby_to_object(rule)
          if rule_obj.null? || rule_obj[:type] == :ddwaf_object_invalid
            fail LibDDWAF::Error, "Could not convert object #{rule.inspect}"
          end

          config_obj = Datadog::AppSec::WAF::LibDDWAF::Config.new
          if config_obj.null?
            fail LibDDWAF::Error, 'Could not create config struct'
          end

          config_obj[:limits][:max_container_size]  = limits[:max_container_size]  || LibDDWAF::DEFAULT_MAX_CONTAINER_SIZE
          config_obj[:limits][:max_container_depth] = limits[:max_container_depth] || LibDDWAF::DEFAULT_MAX_CONTAINER_DEPTH
          config_obj[:limits][:max_string_length]   = limits[:max_string_length]   || LibDDWAF::DEFAULT_MAX_STRING_LENGTH
          config_obj[:obfuscator][:key_regex]       = FFI::MemoryPointer.from_string(obfuscator[:key_regex])   if obfuscator[:key_regex]
          config_obj[:obfuscator][:value_regex]     = FFI::MemoryPointer.from_string(obfuscator[:value_regex]) if obfuscator[:value_regex]
          config_obj[:free_fn] = Datadog::AppSec::WAF::LibDDWAF::ObjectNoFree

          @config = config_obj

          diagnostics_obj = Datadog::AppSec::WAF::LibDDWAF::Object.new

          @handle_obj = Datadog::AppSec::WAF::LibDDWAF.ddwaf_init(rule_obj, config_obj, diagnostics_obj)

          @diagnostics = Datadog::AppSec::WAF.object_to_ruby(diagnostics_obj)

          if @handle_obj.null?
            fail LibDDWAF::Error.new('Could not create handle', diagnostics: @diagnostics)
          end

          validate!
        ensure
          Datadog::AppSec::WAF::LibDDWAF.ddwaf_object_free(diagnostics_obj) if diagnostics_obj
          Datadog::AppSec::WAF::LibDDWAF.ddwaf_object_free(rule_obj) if rule_obj
        end

        def finalize
          invalidate!

          Datadog::AppSec::WAF::LibDDWAF.ddwaf_destroy(handle_obj)
        end

        def required_addresses
          valid!

          count = Datadog::AppSec::WAF::LibDDWAF::UInt32Ptr.new
          list = Datadog::AppSec::WAF::LibDDWAF.ddwaf_required_addresses(handle_obj, count)

          return [] if count == 0 # list is null

          list.get_array_of_string(0, count[:value])
        end

        def merge(data)
          data_obj = Datadog::AppSec::WAF.ruby_to_object(data, coerce: false)
          diagnostics_obj = LibDDWAF::Object.new
          new_handle = Datadog::AppSec::WAF::LibDDWAF.ddwaf_update(handle_obj, data_obj, diagnostics_obj)

          return if new_handle.null?

          diagnostics = Datadog::AppSec::WAF.object_to_ruby(diagnostics_obj)
          new_from_handle(new_handle, diagnostics, config)
        ensure
          Datadog::AppSec::WAF::LibDDWAF.ddwaf_object_free(data_obj) if data_obj
          Datadog::AppSec::WAF::LibDDWAF.ddwaf_object_free(diagnostics_obj) if diagnostics_obj
        end

        private

        def new_from_handle(handle_object, diagnostics, config)
          obj = self.class.allocate
          obj.instance_variable_set(:@handle_obj, handle_object)
          obj.instance_variable_set(:@diagnostics, diagnostics)
          obj.instance_variable_set(:@config, config)
          obj
        end

        def validate!
          @valid = true
        end

        def invalidate!
          @valid = false
        end

        def valid?
          @valid
        end

        def valid!
          return if valid?

          fail LibDDWAF::Error, "Attempt to use an invalid instance: #{inspect}"
        end
      end

      class Result
        attr_reader :status, :events, :total_runtime, :timeout, :actions, :derivatives

        def initialize(status, events, total_runtime, timeout, actions, derivatives)
          @status = status
          @events = events
          @total_runtime = total_runtime
          @timeout = timeout
          @actions = actions
          @derivatives = derivatives
        end
      end

      class Context
        attr_reader :context_obj

        def initialize(handle)
          handle_obj = handle.handle_obj
          retain(handle)

          @context_obj = Datadog::AppSec::WAF::LibDDWAF.ddwaf_context_init(handle_obj)
          if @context_obj.null?
            fail LibDDWAF::Error, 'Could not create context'
          end

          validate!
        end

        def finalize
          invalidate!

          retained.each do |retained_obj|
            next unless retained_obj.is_a?(Datadog::AppSec::WAF::LibDDWAF::Object)

            Datadog::AppSec::WAF::LibDDWAF.ddwaf_object_free(retained_obj)
          end

          Datadog::AppSec::WAF::LibDDWAF.ddwaf_context_destroy(context_obj)
        end

        def run(input, timeout = LibDDWAF::DDWAF_RUN_TIMEOUT)
          valid!

          max_container_size  = LibDDWAF::DDWAF_MAX_CONTAINER_SIZE
          max_container_depth = LibDDWAF::DDWAF_MAX_CONTAINER_DEPTH
          max_string_length   = LibDDWAF::DDWAF_MAX_STRING_LENGTH

          input_obj = Datadog::AppSec::WAF.ruby_to_object(input,
                                                          max_container_size: max_container_size,
                                                          max_container_depth: max_container_depth,
                                                          max_string_length: max_string_length,
                                                          coerce: false)
          if input_obj.null?
            fail LibDDWAF::Error, "Could not convert input: #{input.inspect}"
          end

          result_obj = Datadog::AppSec::WAF::LibDDWAF::Result.new
          if result_obj.null?
            fail LibDDWAF::Error, "Could not create result object"
          end

          # retain C objects in memory for subsequent calls to run
          retain(input_obj)

          code = Datadog::AppSec::WAF::LibDDWAF.ddwaf_run(@context_obj, input_obj, result_obj, timeout)

          result = Result.new(
            RESULT_CODE[code],
            Datadog::AppSec::WAF.object_to_ruby(result_obj[:events]),
            result_obj[:total_runtime],
            result_obj[:timeout],
            Datadog::AppSec::WAF.object_to_ruby(result_obj[:actions]),
            Datadog::AppSec::WAF.object_to_ruby(result_obj[:derivatives]),
          )

          [RESULT_CODE[code], result]
        ensure
          Datadog::AppSec::WAF::LibDDWAF.ddwaf_result_free(result_obj) if result_obj
        end

        private

        def validate!
          @valid = true
        end

        def invalidate!
          @valid = false
        end

        def valid?
          @valid
        end

        def valid!
          return if valid?

          fail LibDDWAF::Error, "Attempt to use an invalid instance: #{inspect}"
        end

        def retained
          @retained ||= []
        end

        def retain(object)
          retained << object
        end

        def release(object)
          retained.delete(object)
        end
      end
    end
    # rubocop:enable Metrics/ModuleLength
  end
end
