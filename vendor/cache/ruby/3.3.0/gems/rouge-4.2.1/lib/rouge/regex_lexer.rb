# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  # @abstract
  # A stateful lexer that uses sets of regular expressions to
  # tokenize a string.  Most lexers are instances of RegexLexer.
  class RegexLexer < Lexer
    class InvalidRegex < StandardError
      def initialize(re)
        @re = re
      end

      def to_s
        "regex #{@re.inspect} matches empty string, but has no predicate!"
      end
    end

    class ClosedState < StandardError
      attr_reader :state
      def initialize(state)
        @state = state
      end

      def rule
        @state.rules.last
      end

      def to_s
        rule = @state.rules.last
        msg = "State :#{state.name} cannot continue after #{rule.inspect}, which will always match."
        if rule.re.source.include?('*')
          msg += " Consider replacing * with +."
        end

        msg
      end
    end

    # A rule is a tuple of a regular expression to test, and a callback
    # to perform if the test succeeds.
    #
    # @see StateDSL#rule
    class Rule
      attr_reader :callback
      attr_reader :re
      attr_reader :beginning_of_line
      def initialize(re, callback)
        @re = re
        @callback = callback
        @beginning_of_line = re.source[0] == ?^
      end

      def inspect
        "#<Rule #{@re.inspect}>"
      end
    end

    # a State is a named set of rules that can be tested for or
    # mixed in.
    #
    # @see RegexLexer.state
    class State
      attr_reader :name, :rules
      def initialize(name, rules)
        @name = name
        @rules = rules
      end

      def inspect
        "#<#{self.class.name} #{@name.inspect}>"
      end
    end

    class StateDSL
      attr_reader :rules, :name
      def initialize(name, &defn)
        @name = name
        @defn = defn
        @rules = []
        @loaded = false
        @closed = false
      end

      def to_state(lexer_class)
        load!
        rules = @rules.map do |rule|
          rule.is_a?(String) ? lexer_class.get_state(rule) : rule
        end
        State.new(@name, rules)
      end

      def prepended(&defn)
        parent_defn = @defn
        StateDSL.new(@name) do
          instance_eval(&defn)
          instance_eval(&parent_defn)
        end
      end

      def appended(&defn)
        parent_defn = @defn
        StateDSL.new(@name) do
          instance_eval(&parent_defn)
          instance_eval(&defn)
        end
      end

    protected
      # Define a new rule for this state.
      #
      # @overload rule(re, token, next_state=nil)
      # @overload rule(re, &callback)
      #
      # @param [Regexp] re
      #   a regular expression for this rule to test.
      # @param [String] tok
      #   the token type to yield if `re` matches.
      # @param [#to_s] next_state
      #   (optional) a state to push onto the stack if `re` matches.
      #   If `next_state` is `:pop!`, the state stack will be popped
      #   instead.
      # @param [Proc] callback
      #   a block that will be evaluated in the context of the lexer
      #   if `re` matches.  This block has access to a number of lexer
      #   methods, including {RegexLexer#push}, {RegexLexer#pop!},
      #   {RegexLexer#token}, and {RegexLexer#delegate}.  The first
      #   argument can be used to access the match groups.
      def rule(re, tok=nil, next_state=nil, &callback)
        raise ClosedState.new(self) if @closed

        if tok.nil? && callback.nil?
          raise "please pass `rule` a token to yield or a callback"
        end

        matches_empty = re =~ ''

        callback ||= case next_state
        when :pop!
          proc do |stream|
            puts "    yielding: #{tok.qualname}, #{stream[0].inspect}" if @debug
            @output_stream.call(tok, stream[0])
            puts "    popping stack: 1" if @debug
            @stack.pop or raise 'empty stack!'
          end
        when :push
          proc do |stream|
            puts "    yielding: #{tok.qualname}, #{stream[0].inspect}" if @debug
            @output_stream.call(tok, stream[0])
            puts "    pushing :#{@stack.last.name}" if @debug
            @stack.push(@stack.last)
          end
        when Symbol
          proc do |stream|
            puts "    yielding: #{tok.qualname}, #{stream[0].inspect}" if @debug
            @output_stream.call(tok, stream[0])
            state = @states[next_state] || self.class.get_state(next_state)
            puts "    pushing :#{state.name}" if @debug
            @stack.push(state)
          end
        when nil
          # cannot use an empty-matching regexp with no predicate
          raise InvalidRegex.new(re) if matches_empty

          proc do |stream|
            puts "    yielding: #{tok.qualname}, #{stream[0].inspect}" if @debug
            @output_stream.call(tok, stream[0])
          end
        else
          raise "invalid next state: #{next_state.inspect}"
        end

        rules << Rule.new(re, callback)

        close! if matches_empty && !context_sensitive?(re)
      end

      def context_sensitive?(re)
        source = re.source
        return true if source =~ /[(][?]<?[!=]/

        # anchors count as lookahead/behind
        return true if source =~ /[$^]/

        false
      end

      def close!
        @closed = true
      end

      # Mix in the rules from another state into this state.  The rules
      # from the mixed-in state will be tried in order before moving on
      # to the rest of the rules in this state.
      def mixin(state)
        rules << state.to_s
      end

    private
      def load!
        return if @loaded
        @loaded = true
        instance_eval(&@defn)
      end
    end

    # The states hash for this lexer.
    # @see state
    def self.states
      @states ||= {}
    end

    def self.state_definitions
      @state_definitions ||= InheritableHash.new(superclass.state_definitions)
    end
    @state_definitions = {}

    def self.replace_state(name, new_defn)
      states[name] = nil
      state_definitions[name] = new_defn
    end

    # The routines to run at the beginning of a fresh lex.
    # @see start
    def self.start_procs
      @start_procs ||= InheritableList.new(superclass.start_procs)
    end
    @start_procs = []

    # Specify an action to be run every fresh lex.
    #
    # @example
    #   start { puts "I'm lexing a new string!" }
    def self.start(&b)
      start_procs << b
    end

    # Define a new state for this lexer with the given name.
    # The block will be evaluated in the context of a {StateDSL}.
    def self.state(name, &b)
      name = name.to_sym
      state_definitions[name] = StateDSL.new(name, &b)
    end

    def self.prepend(name, &b)
      name = name.to_sym
      dsl = state_definitions[name] or raise "no such state #{name.inspect}"
      replace_state(name, dsl.prepended(&b))
    end

    def self.append(name, &b)
      name = name.to_sym
      dsl = state_definitions[name] or raise "no such state #{name.inspect}"
      replace_state(name, dsl.appended(&b))
    end

    # @private
    def self.get_state(name)
      return name if name.is_a? State

      states[name.to_sym] ||= begin
        defn = state_definitions[name.to_sym] or raise "unknown state: #{name.inspect}"
        defn.to_state(self)
      end
    end

    # @private
    def get_state(state_name)
      self.class.get_state(state_name)
    end

    # The state stack.  This is initially the single state `[:root]`.
    # It is an error for this stack to be empty.
    # @see #state
    def stack
      @stack ||= [get_state(:root)]
    end

    # The current state - i.e. one on top of the state stack.
    #
    # NB: if the state stack is empty, this will throw an error rather
    # than returning nil.
    def state
      stack.last or raise 'empty stack!'
    end

    # reset this lexer to its initial state.  This runs all of the
    # start_procs.
    def reset!
      @stack = nil
      @current_stream = nil

      puts "start blocks" if @debug && self.class.start_procs.any?
      self.class.start_procs.each do |pr|
        instance_eval(&pr)
      end
    end

    # This implements the lexer protocol, by yielding [token, value] pairs.
    #
    # The process for lexing works as follows, until the stream is empty:
    #
    # 1. We look at the state on top of the stack (which by default is
    #    `[:root]`).
    # 2. Each rule in that state is tried until one is successful.  If one
    #    is found, that rule's callback is evaluated - which may yield
    #    tokens and manipulate the state stack.  Otherwise, one character
    #    is consumed with an `'Error'` token, and we continue at (1.)
    #
    # @see #step #step (where (2.) is implemented)
    def stream_tokens(str, &b)
      stream = StringScanner.new(str)

      @current_stream = stream
      @output_stream  = b
      @states         = self.class.states
      @null_steps     = 0

      until stream.eos?
        if @debug
          puts
          puts "lexer: #{self.class.tag}"
          puts "stack: #{stack.map(&:name).map(&:to_sym).inspect}"
          puts "stream: #{stream.peek(20).inspect}"
        end

        success = step(state, stream)

        if !success
          puts "    no match, yielding Error" if @debug
          b.call(Token::Tokens::Error, stream.getch)
        end
      end
    end

    # The number of successive scans permitted without consuming
    # the input stream.  If this is exceeded, the match fails.
    MAX_NULL_SCANS = 5

    # Runs one step of the lex.  Rules in the current state are tried
    # until one matches, at which point its callback is called.
    #
    # @return true if a rule was tried successfully
    # @return false otherwise.
    def step(state, stream)
      state.rules.each do |rule|
        if rule.is_a?(State)
          puts "  entering: mixin :#{rule.name}" if @debug
          return true if step(rule, stream)
          puts "  exiting: mixin :#{rule.name}" if @debug
        else
          puts "  trying: #{rule.inspect}" if @debug

          # XXX HACK XXX
          # StringScanner's implementation of ^ is b0rken.
          # see http://bugs.ruby-lang.org/issues/7092
          # TODO: this doesn't cover cases like /(a|^b)/, but it's
          # the most common, for now...
          next if rule.beginning_of_line && !stream.beginning_of_line?

          if (size = stream.skip(rule.re))
            puts "    got: #{stream[0].inspect}" if @debug

            instance_exec(stream, &rule.callback)

            if size.zero?
              @null_steps += 1
              if @null_steps > MAX_NULL_SCANS
                puts "    warning: too many scans without consuming the string!" if @debug
                return false
              end
            else
              @null_steps = 0
            end

            return true
          end
        end
      end

      false
    end

    # Yield a token.
    #
    # @param tok
    #   the token type
    # @param val
    #   (optional) the string value to yield.  If absent, this defaults
    #   to the entire last match.
    def token(tok, val=@current_stream[0])
      yield_token(tok, val)
    end

    # @deprecated
    #
    # Yield a token with the next matched group.  Subsequent calls
    # to this method will yield subsequent groups.
    def group(tok)
      raise "RegexLexer#group is deprecated: use #groups instead"
    end

    # Yield tokens corresponding to the matched groups of the current
    # match.
    def groups(*tokens)
      tokens.each_with_index do |tok, i|
        yield_token(tok, @current_stream[i+1])
      end
    end

    # Delegate the lex to another lexer. We use the `continue_lex` method
    # so that #reset! will not be called.  In this way, a single lexer
    # can be repeatedly delegated to while maintaining its own internal
    # state stack.
    #
    # @param [#lex] lexer
    #   The lexer or lexer class to delegate to
    # @param [String] text
    #   The text to delegate.  This defaults to the last matched string.
    def delegate(lexer, text=nil)
      puts "    delegating to: #{lexer.inspect}" if @debug
      text ||= @current_stream[0]

      lexer.continue_lex(text) do |tok, val|
        puts "    delegated token: #{tok.inspect}, #{val.inspect}" if @debug
        yield_token(tok, val)
      end
    end

    def recurse(text=nil)
      delegate(self.class, text)
    end

    # Push a state onto the stack.  If no state name is given and you've
    # passed a block, a state will be dynamically created using the
    # {StateDSL}.
    def push(state_name=nil, &b)
      push_state = if state_name
        get_state(state_name)
      elsif block_given?
        StateDSL.new(b.inspect, &b).to_state(self.class)
      else
        # use the top of the stack by default
        self.state
      end

      puts "    pushing: :#{push_state.name}" if @debug
      stack.push(push_state)
    end

    # Pop the state stack.  If a number is passed in, it will be popped
    # that number of times.
    def pop!(times=1)
      raise 'empty stack!' if stack.empty?

      puts "    popping stack: #{times}" if @debug

      stack.pop(times)

      nil
    end

    # replace the head of the stack with the given state
    def goto(state_name)
      raise 'empty stack!' if stack.empty?

      puts "    going to: state :#{state_name} " if @debug
      stack[-1] = get_state(state_name)
    end

    # reset the stack back to `[:root]`.
    def reset_stack
      puts '    resetting stack' if @debug
      stack.clear
      stack.push get_state(:root)
    end

    # Check if `state_name` is in the state stack.
    def in_state?(state_name)
      state_name = state_name.to_sym
      stack.any? do |state|
        state.name == state_name.to_sym
      end
    end

    # Check if `state_name` is the state on top of the state stack.
    def state?(state_name)
      state_name.to_sym == state.name
    end

  private
    def yield_token(tok, val)
      return if val.nil? || val.empty?
      puts "    yielding: #{tok.qualname}, #{val.inspect}" if @debug
      @output_stream.yield(tok, val)
    end
  end
end
