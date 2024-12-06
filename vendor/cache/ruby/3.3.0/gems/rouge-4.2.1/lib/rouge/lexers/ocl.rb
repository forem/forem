module Rouge
  module Lexers
    class OCL < RegexLexer
      title "OCL"
      desc "OMG Object Constraint Language (omg.org/spec/OCL)"
      tag 'ocl'
      aliases 'OCL'
      filenames '*.ocl'
      mimetypes 'text/x-ocl'

      def self.keywords
        @keywords ||= Set.new %w(
          context pre post inv init body def derive if then else endif import
          package endpackage let in
        )
      end

      def self.keywords_type
        @keywords_type ||= Set.new %w(
          Boolean Integer UnlimitedNatural Real String OrderedSet Tuple Bag Set
          Sequence OclInvalid OclVoid TupleType OclState Collection OclMessage
        )
      end

      def self.builtins
        @builtins ||= Set.new %w(
          self null result true false invalid @pre
          )
      end

      def self.operators
        @operators ||= Set.new %w(
          or xor and not implies
        )
      end

      def self.functions
        @functions ||= Set.new %w(
          oclAsSet oclIsNew oclIsUndefined oclIsInvalid oclAsType oclIsTypeOf
          oclIsKindOf oclInState oclType oclLocale hasReturned result
          isSignalSent isOperationCallabs floor round max min toString div mod
          size substring concat toInteger toReal toUpperCase toLowerCase
          indexOf equalsIgnoreCase at characters toBoolean includes excludes
          count includesAll excludesAll isEmpty notEmpty sum product
          selectByKind selectByType asBag asSequence asOrderedSet asSet flatten
          union intersection including excluding symmetricDifferencecount
          append prepend insertAt subOrderedSet first last reverse subSequence
          any closure collect collectNested exists forAll isUnique iterate one
          reject select sortedBy allInstances average conformsTo
        )
      end

      state :single_string do
        rule %r/\\./, Str::Escape
        rule %r/'/, Str::Single, :pop!
        rule %r/[^\\']+/, Str::Single
      end

      state :root do
        rule %r/\s+/m, Text
        rule %r/--.*/, Comment::Single
        rule %r/\d+/, Num::Integer
        rule %r/'/, Str::Single, :single_string
        rule %r([-|+*/<>=~!@#%&?^]), Operator
        rule %r/[;:()\[\],.]/, Punctuation
        rule %r/[a-zA-Z]\w*/ do |m|
          if self.class.operators.include? m[0]
            token Operator
          elsif self.class.keywords_type.include? m[0]
            token Keyword::Declaration
          elsif self.class.keywords.include? m[0]
            token Keyword
          elsif self.class.builtins.include? m[0]
            token Name::Builtin
          elsif self.class.functions.include? m[0]
            token Name::Function
          else
            token Name
          end
        end
      end
    end
  end
end
