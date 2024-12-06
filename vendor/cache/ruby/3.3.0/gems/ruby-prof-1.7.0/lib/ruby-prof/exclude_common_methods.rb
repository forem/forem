require 'set'

# :enddoc:
module RubyProf
  module ExcludeCommonMethods
    ENUMERABLE_NAMES = Enumerable.instance_methods(false)

    def self.apply!(profile)
      ##
      #  Kernel Methods
      ##

      exclude_methods(profile, Kernel, [
        :dup,
        :initialize_dup,
        :tap,
        :send,
        :public_send,
      ])

      ##
      #  Fundamental Types
      ##

      exclude_methods(profile, BasicObject,  :!=)
      exclude_methods(profile, Kernel,       :"block_given?")
      exclude_methods(profile, Method,       :[])
      exclude_methods(profile, Module,       :new)
      exclude_methods(profile, Class,        :new)
      exclude_methods(profile, Proc,         :call, :yield)
      exclude_methods(profile, Range,        :each)

      ##
      #  Value Types
      ##

      exclude_methods(profile, Integer, [
        :times,
        :succ,
        :<
      ])

      exclude_methods(profile, String, [
        :sub,
        :sub!,
        :gsub,
        :gsub!,
      ])

      ##
      #  Emumerables
      ##

      exclude_enumerable(profile, Enumerable)
      exclude_enumerable(profile, Enumerator)

      ##
      #  Collections
      ##

      exclude_enumerable(profile, Array, [
        :each_index,
        :map!,
        :select!,
        :reject!,
        :collect!,
        :sort!,
        :sort_by!,
        :index,
        :delete_if,
        :keep_if,
        :drop_while,
        :uniq,
        :uniq!,
        :"==",
        :eql?,
        :hash,
        :to_json,
        :as_json,
        :encode_json,
      ])

      exclude_enumerable(profile, Hash, [
        :dup,
        :initialize_dup,
        :fetch,
        :"[]",
        :"[]=",
        :each_key,
        :each_value,
        :each_pair,
        :map!,
        :select!,
        :reject!,
        :collect!,
        :delete_if,
        :keep_if,
        :slice,
        :slice!,
        :except,
        :except!,
        :"==",
        :eql?,
        :hash,
        :to_json,
        :as_json,
        :encode_json,
      ])

      exclude_enumerable(profile, Set, [
        :map!,
        :select!,
        :reject!,
        :collect!,
        :classify,
        :delete_if,
        :keep_if,
        :divide,
        :"==",
        :eql?,
        :hash,
        :to_json,
        :as_json,
        :encode_json,
      ])

      ##
      #  Garbage Collection
      ##

      exclude_singleton_methods(profile, GC, [
        :start
      ])

      ##
      #  Unicorn
      ##

      if defined?(Unicorn)
        exclude_methods(profile, Unicorn::HttpServer, :process_client)
      end

      if defined?(Unicorn::OobGC)
        exclude_methods(profile, Unicorn::OobGC, :process_client)
      end

      ##
      #  New Relic
      ##

      if defined?(NewRelic::Agent)
        if defined?(NewRelic::Agent::Instrumentation::MiddlewareTracing)
          exclude_methods(profile, NewRelic::Agent::Instrumentation::MiddlewareTracing, [
            :call
          ])
        end

        if defined?(NewRelic::Agent::MethodTracerHelpers)
          exclude_methods(profile, NewRelic::Agent::MethodTracerHelpers, [
            :trace_execution_scoped,
            :log_errors,
          ])

          exclude_singleton_methods(profile, NewRelic::Agent::MethodTracerHelpers, [
            :trace_execution_scoped,
            :log_errors,
          ])
        end

        if defined?(NewRelic::Agent::MethodTracer)
          exclude_methods(profile, NewRelic::Agent::MethodTracer, [
            :trace_execution_scoped,
            :trace_execution_unscoped,
          ])
        end
      end

        ##
        #  Miscellaneous Methods
        ##

      if defined?(Mustache)
        exclude_methods(profile, Mustache::Context, [
          :fetch
        ])
      end
    end

    private

    def self.exclude_enumerable(profile, mod, *method_or_methods)
      exclude_methods(profile, mod, [:each, *method_or_methods])
      exclude_methods(profile, mod, ENUMERABLE_NAMES)
    end

    def self.exclude_methods(profile, mod, *method_or_methods)
      profile.exclude_methods!(mod, method_or_methods)
    end

    def self.exclude_singleton_methods(profile, mod, *method_or_methods)
      profile.exclude_singleton_methods!(mod, method_or_methods)
    end
  end
end
