module BetterErrors
  class ExceptionHint
    def initialize(exception)
      @exception = exception
    end

    def hint
      case exception
      when NoMethodError
        /\Aundefined method `(?<method>[^']+)' for (?<val>[^:]+):(?<klass>\w+)/.match(exception.message) do |match|
          if match[:val] == "nil"
            return "Something is `nil` when it probably shouldn't be."
          elsif !match[:klass].start_with? '0x'
            return "`#{match[:method]}` is being called on a `#{match[:klass]}` object, "\
              "which might not be the type of object you were expecting."
          end
        end
      when NameError
        /\Aundefined local variable or method `(?<method>[^']+)' for/.match(exception.message) do |match|
          return "`#{match[:method]}` is probably misspelled."
        end
      end
    end

    private

    attr_reader :exception
  end
end
