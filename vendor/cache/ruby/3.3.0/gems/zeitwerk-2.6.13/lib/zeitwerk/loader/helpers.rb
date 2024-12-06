# frozen_string_literal: true

module Zeitwerk::Loader::Helpers
  # --- Logging -----------------------------------------------------------------------------------

  # @sig (String) -> void
  private def log(message)
    method_name = logger.respond_to?(:debug) ? :debug : :call
    logger.send(method_name, "Zeitwerk@#{tag}: #{message}")
  end

  # --- Files and directories ---------------------------------------------------------------------

  # @sig (String) { (String, String) -> void } -> void
  private def ls(dir)
    children = Dir.children(dir)

    # The order in which a directory is listed depends on the file system.
    #
    # Since client code may run in different platforms, it seems convenient to
    # order directory entries. This provides consistent eager loading across
    # platforms, for example.
    children.sort!

    children.each do |basename|
      next if hidden?(basename)

      abspath = File.join(dir, basename)
      next if ignored_path?(abspath)

      if dir?(abspath)
        next if roots.key?(abspath)
        next if !has_at_least_one_ruby_file?(abspath)
      else
        next unless ruby?(abspath)
      end

      # We freeze abspath because that saves allocations when passed later to
      # File methods. See #125.
      yield basename, abspath.freeze
    end
  end

  # @sig (String) -> bool
  private def has_at_least_one_ruby_file?(dir)
    to_visit = [dir]

    while dir = to_visit.shift
      ls(dir) do |_basename, abspath|
        if dir?(abspath)
          to_visit << abspath
        else
          return true
        end
      end
    end

    false
  end

  # @sig (String) -> bool
  private def ruby?(path)
    path.end_with?(".rb")
  end

  # @sig (String) -> bool
  private def dir?(path)
    File.directory?(path)
  end

  # @sig (String) -> bool
  private def hidden?(basename)
    basename.start_with?(".")
  end

  # @sig (String) { (String) -> void } -> void
  private def walk_up(abspath)
    loop do
      yield abspath
      abspath, basename = File.split(abspath)
      break if basename == "/"
    end
  end

  # --- Constants ---------------------------------------------------------------------------------

  # The autoload? predicate takes into account the ancestor chain of the
  # receiver, like const_defined? and other methods in the constants API do.
  #
  # For example, given
  #
  #   class A
  #     autoload :X, "x.rb"
  #   end
  #
  #   class B < A
  #   end
  #
  # B.autoload?(:X) returns "x.rb".
  #
  # We need a way to strictly check in parent ignoring ancestors.
  #
  # @sig (Module, Symbol) -> String?
  if method(:autoload?).arity == 1
    private def strict_autoload_path(parent, cname)
      parent.autoload?(cname) if cdef?(parent, cname)
    end
  else
    private def strict_autoload_path(parent, cname)
      parent.autoload?(cname, false)
    end
  end

  # @sig (Module, Symbol) -> String
  if Symbol.method_defined?(:name)
    # Symbol#name was introduced in Ruby 3.0. It returns always the same
    # frozen object, so we may save a few string allocations.
    private def cpath(parent, cname)
      Object == parent ? cname.name : "#{real_mod_name(parent)}::#{cname.name}"
    end
  else
    private def cpath(parent, cname)
      Object == parent ? cname.to_s : "#{real_mod_name(parent)}::#{cname}"
    end
  end

  # @sig (Module, Symbol) -> bool
  private def cdef?(parent, cname)
    parent.const_defined?(cname, false)
  end

  # @raise [NameError]
  # @sig (Module, Symbol) -> Object
  private def cget(parent, cname)
    parent.const_get(cname, false)
  end

  # @raise [NameError]
  # @sig (Module, Symbol) -> Object
  private def crem(parent, cname)
    parent.__send__(:remove_const, cname)
  end

  CNAME_VALIDATOR = Module.new
  private_constant :CNAME_VALIDATOR

  # @raise [Zeitwerk::NameError]
  # @sig (String, String) -> Symbol
  private def cname_for(basename, abspath)
    cname = inflector.camelize(basename, abspath)

    unless cname.is_a?(String)
      raise TypeError, "#{inflector.class}#camelize must return a String, received #{cname.inspect}"
    end

    if cname.include?("::")
      raise Zeitwerk::NameError.new(<<~MESSAGE, cname)
        wrong constant name #{cname} inferred by #{inflector.class} from

          #{abspath}

        #{inflector.class}#camelize should return a simple constant name without "::"
      MESSAGE
    end

    begin
      CNAME_VALIDATOR.const_defined?(cname, false)
    rescue ::NameError => error
      path_type = ruby?(abspath) ? "file" : "directory"

      raise Zeitwerk::NameError.new(<<~MESSAGE, error.name)
        #{error.message} inferred by #{inflector.class} from #{path_type}

          #{abspath}

        Possible ways to address this:

          * Tell Zeitwerk to ignore this particular #{path_type}.
          * Tell Zeitwerk to ignore one of its parent directories.
          * Rename the #{path_type} to comply with the naming conventions.
          * Modify the inflector to handle this case.
      MESSAGE
    end

    cname.to_sym
  end
end
