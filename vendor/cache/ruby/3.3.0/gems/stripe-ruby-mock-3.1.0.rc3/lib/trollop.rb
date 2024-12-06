## lib/trollop.rb -- trollop command-line processing library
## Author::    William Morgan (mailto: wmorgan-trollop@masanjin.net)
## Copyright:: Copyright 2007 William Morgan
## License::   the same terms as ruby itself

require 'date'

module Trollop

VERSION = "2.0"

## Thrown by Parser in the event of a commandline error. Not needed if
## you're using the Trollop::options entry.
class CommandlineError < StandardError; end

## Thrown by Parser if the user passes in '-h' or '--help'. Handled
## automatically by Trollop#options.
class HelpNeeded < StandardError; end

## Thrown by Parser if the user passes in '-h' or '--version'. Handled
## automatically by Trollop#options.
class VersionNeeded < StandardError; end

## Regex for floating point numbers
FLOAT_RE = /^-?((\d+(\.\d+)?)|(\.\d+))([eE][-+]?[\d]+)?$/

## Regex for parameters
PARAM_RE = /^-(-|\.$|[^\d\.])/

## The commandline parser. In typical usage, the methods in this class
## will be handled internally by Trollop::options. In this case, only the
## #opt, #banner and #version, #depends, and #conflicts methods will
## typically be called.
##
## If you want to instantiate this class yourself (for more complicated
## argument-parsing logic), call #parse to actually produce the output hash,
## and consider calling it from within
## Trollop::with_standard_exception_handling.
class Parser

  ## The set of values that indicate a flag option when passed as the
  ## +:type+ parameter of #opt.
  FLAG_TYPES = [:flag, :bool, :boolean]

  ## The set of values that indicate a single-parameter (normal) option when
  ## passed as the +:type+ parameter of #opt.
  ##
  ## A value of +io+ corresponds to a readable IO resource, including
  ## a filename, URI, or the strings 'stdin' or '-'.
  SINGLE_ARG_TYPES = [:int, :integer, :string, :double, :float, :io, :date]

  ## The set of values that indicate a multiple-parameter option (i.e., that
  ## takes multiple space-separated values on the commandline) when passed as
  ## the +:type+ parameter of #opt.
  MULTI_ARG_TYPES = [:ints, :integers, :strings, :doubles, :floats, :ios, :dates]

  ## The complete set of legal values for the +:type+ parameter of #opt.
  TYPES = FLAG_TYPES + SINGLE_ARG_TYPES + MULTI_ARG_TYPES

  INVALID_SHORT_ARG_REGEX = /[\d-]/ #:nodoc:

  ## The values from the commandline that were not interpreted by #parse.
  attr_reader :leftovers

  ## The complete configuration hashes for each option. (Mainly useful
  ## for testing.)
  attr_reader :specs

  ## Initializes the parser, and instance-evaluates any block given.
  def initialize *a, &b
    @version = nil
    @leftovers = []
    @specs = {}
    @long = {}
    @short = {}
    @order = []
    @constraints = []
    @stop_words = []
    @stop_on_unknown = false

    #instance_eval(&b) if b # can't take arguments
    cloaker(&b).bind(self).call(*a) if b
  end

  ## Define an option. +name+ is the option name, a unique identifier
  ## for the option that you will use internally, which should be a
  ## symbol or a string. +desc+ is a string description which will be
  ## displayed in help messages.
  ##
  ## Takes the following optional arguments:
  ##
  ## [+:long+] Specify the long form of the argument, i.e. the form with two dashes. If unspecified, will be automatically derived based on the argument name by turning the +name+ option into a string, and replacing any _'s by -'s.
  ## [+:short+] Specify the short form of the argument, i.e. the form with one dash. If unspecified, will be automatically derived from +name+.
  ## [+:type+] Require that the argument take a parameter or parameters of type +type+. For a single parameter, the value can be a member of +SINGLE_ARG_TYPES+, or a corresponding Ruby class (e.g. +Integer+ for +:int+). For multiple-argument parameters, the value can be any member of +MULTI_ARG_TYPES+ constant. If unset, the default argument type is +:flag+, meaning that the argument does not take a parameter. The specification of +:type+ is not necessary if a +:default+ is given.
  ## [+:default+] Set the default value for an argument. Without a default value, the hash returned by #parse (and thus Trollop::options) will have a +nil+ value for this key unless the argument is given on the commandline. The argument type is derived automatically from the class of the default value given, so specifying a +:type+ is not necessary if a +:default+ is given. (But see below for an important caveat when +:multi+: is specified too.) If the argument is a flag, and the default is set to +true+, then if it is specified on the the commandline the value will be +false+.
  ## [+:required+] If set to +true+, the argument must be provided on the commandline.
  ## [+:multi+] If set to +true+, allows multiple occurrences of the option on the commandline. Otherwise, only a single instance of the option is allowed. (Note that this is different from taking multiple parameters. See below.)
  ##
  ## Note that there are two types of argument multiplicity: an argument
  ## can take multiple values, e.g. "--arg 1 2 3". An argument can also
  ## be allowed to occur multiple times, e.g. "--arg 1 --arg 2".
  ##
  ## Arguments that take multiple values should have a +:type+ parameter
  ## drawn from +MULTI_ARG_TYPES+ (e.g. +:strings+), or a +:default:+
  ## value of an array of the correct type (e.g. [String]). The
  ## value of this argument will be an array of the parameters on the
  ## commandline.
  ##
  ## Arguments that can occur multiple times should be marked with
  ## +:multi+ => +true+. The value of this argument will also be an array.
  ## In contrast with regular non-multi options, if not specified on
  ## the commandline, the default value will be [], not nil.
  ##
  ## These two attributes can be combined (e.g. +:type+ => +:strings+,
  ## +:multi+ => +true+), in which case the value of the argument will be
  ## an array of arrays.
  ##
  ## There's one ambiguous case to be aware of: when +:multi+: is true and a
  ## +:default+ is set to an array (of something), it's ambiguous whether this
  ## is a multi-value argument as well as a multi-occurrence argument.
  ## In thise case, Trollop assumes that it's not a multi-value argument.
  ## If you want a multi-value, multi-occurrence argument with a default
  ## value, you must specify +:type+ as well.

  def opt name, desc="", opts={}
    raise ArgumentError, "you already have an argument named '#{name}'" if @specs.member? name

    ## fill in :type
    opts[:type] = # normalize
      case opts[:type]
      when :boolean, :bool; :flag
      when :integer; :int
      when :integers; :ints
      when :double; :float
      when :doubles; :floats
      when Class
        case opts[:type].name
        when 'TrueClass', 'FalseClass'; :flag
        when 'String'; :string
        when 'Integer'; :int
        when 'Float'; :float
        when 'IO'; :io
        when 'Date'; :date
        else
          raise ArgumentError, "unsupported argument type '#{opts[:type].class.name}'"
        end
      when nil; nil
      else
        raise ArgumentError, "unsupported argument type '#{opts[:type]}'" unless TYPES.include?(opts[:type])
        opts[:type]
      end

    ## for options with :multi => true, an array default doesn't imply
    ## a multi-valued argument. for that you have to specify a :type
    ## as well. (this is how we disambiguate an ambiguous situation;
    ## see the docs for Parser#opt for details.)
    disambiguated_default = if opts[:multi] && opts[:default].is_a?(Array) && !opts[:type]
      opts[:default].first
    else
      opts[:default]
    end

    type_from_default =
      case disambiguated_default
      when Integer; :int
      when Numeric; :float
      when TrueClass, FalseClass; :flag
      when String; :string
      when IO; :io
      when Date; :date
      when Array
        if opts[:default].empty?
          raise ArgumentError, "multiple argument type cannot be deduced from an empty array for '#{opts[:default][0].class.name}'"
        end
        case opts[:default][0]    # the first element determines the types
        when Integer; :ints
        when Numeric; :floats
        when String; :strings
        when IO; :ios
        when Date; :dates
        else
          raise ArgumentError, "unsupported multiple argument type '#{opts[:default][0].class.name}'"
        end
      when nil; nil
      else
        raise ArgumentError, "unsupported argument type '#{opts[:default].class.name}'"
      end

    raise ArgumentError, ":type specification and default type don't match (default type is #{type_from_default})" if opts[:type] && type_from_default && opts[:type] != type_from_default

    opts[:type] = opts[:type] || type_from_default || :flag

    ## fill in :long
    opts[:long] = opts[:long] ? opts[:long].to_s : name.to_s.gsub("_", "-")
    opts[:long] = case opts[:long]
      when /^--([^-].*)$/; $1
      when /^[^-]/; opts[:long]
      else; raise ArgumentError, "invalid long option name #{opts[:long].inspect}"
    end
    raise ArgumentError, "long option name #{opts[:long].inspect} is already taken; please specify a (different) :long" if @long[opts[:long]]

    ## fill in :short
    opts[:short] = opts[:short].to_s if opts[:short] unless opts[:short] == :none
    opts[:short] = case opts[:short]
      when /^-(.)$/; $1
      when nil, :none, /^.$/; opts[:short]
      else raise ArgumentError, "invalid short option name '#{opts[:short].inspect}'"
    end

    if opts[:short]
      raise ArgumentError, "short option name #{opts[:short].inspect} is already taken; please specify a (different) :short" if @short[opts[:short]]
      raise ArgumentError, "a short option name can't be a number or a dash" if opts[:short] =~ INVALID_SHORT_ARG_REGEX
    end

    ## fill in :default for flags
    opts[:default] = false if opts[:type] == :flag && opts[:default].nil?

    ## autobox :default for :multi (multi-occurrence) arguments
    opts[:default] = [opts[:default]] if opts[:default] && opts[:multi] && !opts[:default].is_a?(Array)

    ## fill in :multi
    opts[:multi] ||= false

    opts[:desc] ||= desc
    @long[opts[:long]] = name
    @short[opts[:short]] = name if opts[:short] && opts[:short] != :none
    @specs[name] = opts
    @order << [:opt, name]
  end

  ## Sets the version string. If set, the user can request the version
  ## on the commandline. Should probably be of the form "<program name>
  ## <version number>".
  def version s=nil; @version = s if s; @version end

  ## Adds text to the help display. Can be interspersed with calls to
  ## #opt to build a multi-section help page.
  def banner s; @order << [:text, s] end
  alias :text :banner

  ## Marks two (or more!) options as requiring each other. Only handles
  ## undirected (i.e., mutual) dependencies. Directed dependencies are
  ## better modeled with Trollop::die.
  def depends *syms
    syms.each { |sym| raise ArgumentError, "unknown option '#{sym}'" unless @specs[sym] }
    @constraints << [:depends, syms]
  end

  ## Marks two (or more!) options as conflicting.
  def conflicts *syms
    syms.each { |sym| raise ArgumentError, "unknown option '#{sym}'" unless @specs[sym] }
    @constraints << [:conflicts, syms]
  end

  ## Defines a set of words which cause parsing to terminate when
  ## encountered, such that any options to the left of the word are
  ## parsed as usual, and options to the right of the word are left
  ## intact.
  ##
  ## A typical use case would be for subcommand support, where these
  ## would be set to the list of subcommands. A subsequent Trollop
  ## invocation would then be used to parse subcommand options, after
  ## shifting the subcommand off of ARGV.
  def stop_on *words
    @stop_words = [*words].flatten
  end

  ## Similar to #stop_on, but stops on any unknown word when encountered
  ## (unless it is a parameter for an argument). This is useful for
  ## cases where you don't know the set of subcommands ahead of time,
  ## i.e., without first parsing the global options.
  def stop_on_unknown
    @stop_on_unknown = true
  end

  ## Parses the commandline. Typically called by Trollop::options,
  ## but you can call it directly if you need more control.
  ##
  ## throws CommandlineError, HelpNeeded, and VersionNeeded exceptions.
  def parse cmdline=ARGV
    vals = {}
    required = {}

    opt :version, "Print version and exit" if @version unless @specs[:version] || @long["version"]
    opt :help, "Show this message" unless @specs[:help] || @long["help"]

    @specs.each do |sym, opts|
      required[sym] = true if opts[:required]
      vals[sym] = opts[:default]
      vals[sym] = [] if opts[:multi] && !opts[:default] # multi arguments default to [], not nil
    end

    resolve_default_short_options!

    ## resolve symbols
    given_args = {}
    @leftovers = each_arg cmdline do |arg, params|
      ## handle --no- forms
      arg, negative_given = if arg =~ /^--no-([^-]\S*)$/
        ["--#{$1}", true]
      else
        [arg, false]
      end

      sym = case arg
        when /^-([^-])$/; @short[$1]
        when /^--([^-]\S*)$/; @long[$1] || @long["no-#{$1}"]
        else; raise CommandlineError, "invalid argument syntax: '#{arg}'"
      end

      sym = nil if arg =~ /--no-/ # explicitly invalidate --no-no- arguments

      raise CommandlineError, "unknown argument '#{arg}'" unless sym

      if given_args.include?(sym) && !@specs[sym][:multi]
        raise CommandlineError, "option '#{arg}' specified multiple times"
      end

      given_args[sym] ||= {}
      given_args[sym][:arg] = arg
      given_args[sym][:negative_given] = negative_given
      given_args[sym][:params] ||= []

      # The block returns the number of parameters taken.
      num_params_taken = 0

      unless params.nil?
        if SINGLE_ARG_TYPES.include?(@specs[sym][:type])
          given_args[sym][:params] << params[0, 1]  # take the first parameter
          num_params_taken = 1
        elsif MULTI_ARG_TYPES.include?(@specs[sym][:type])
          given_args[sym][:params] << params        # take all the parameters
          num_params_taken = params.size
        end
      end

      num_params_taken
    end

    ## check for version and help args
    raise VersionNeeded if given_args.include? :version
    raise HelpNeeded if given_args.include? :help

    ## check constraint satisfaction
    @constraints.each do |type, syms|
      constraint_sym = syms.find { |sym| given_args[sym] }
      next unless constraint_sym

      case type
      when :depends
        syms.each { |sym| raise CommandlineError, "--#{@specs[constraint_sym][:long]} requires --#{@specs[sym][:long]}" unless given_args.include? sym }
      when :conflicts
        syms.each { |sym| raise CommandlineError, "--#{@specs[constraint_sym][:long]} conflicts with --#{@specs[sym][:long]}" if given_args.include?(sym) && (sym != constraint_sym) }
      end
    end

    required.each do |sym, val|
      raise CommandlineError, "option --#{@specs[sym][:long]} must be specified" unless given_args.include? sym
    end

    ## parse parameters
    given_args.each do |sym, given_data|
      arg, params, negative_given = given_data.values_at :arg, :params, :negative_given

      opts = @specs[sym]
      raise CommandlineError, "option '#{arg}' needs a parameter" if params.empty? && opts[:type] != :flag

      vals["#{sym}_given".intern] = true # mark argument as specified on the commandline

      case opts[:type]
      when :flag
        vals[sym] = (sym.to_s =~ /^no_/ ? negative_given : !negative_given)
      when :int, :ints
        vals[sym] = params.map { |pg| pg.map { |p| parse_integer_parameter p, arg } }
      when :float, :floats
        vals[sym] = params.map { |pg| pg.map { |p| parse_float_parameter p, arg } }
      when :string, :strings
        vals[sym] = params.map { |pg| pg.map { |p| p.to_s } }
      when :io, :ios
        vals[sym] = params.map { |pg| pg.map { |p| parse_io_parameter p, arg } }
      when :date, :dates
        vals[sym] = params.map { |pg| pg.map { |p| parse_date_parameter p, arg } }
      end

      if SINGLE_ARG_TYPES.include?(opts[:type])
        unless opts[:multi]       # single parameter
          vals[sym] = vals[sym][0][0]
        else                      # multiple options, each with a single parameter
          vals[sym] = vals[sym].map { |p| p[0] }
        end
      elsif MULTI_ARG_TYPES.include?(opts[:type]) && !opts[:multi]
        vals[sym] = vals[sym][0]  # single option, with multiple parameters
      end
      # else: multiple options, with multiple parameters
    end

    ## modify input in place with only those
    ## arguments we didn't process
    cmdline.clear
    @leftovers.each { |l| cmdline << l }

    ## allow openstruct-style accessors
    class << vals
      def method_missing(m, *args)
        self[m] || self[m.to_s]
      end
    end
    vals
  end

  def parse_date_parameter param, arg #:nodoc:
    begin
      begin
        time = Chronic.parse(param)
      rescue NameError
        # chronic is not available
      end
      time ? Date.new(time.year, time.month, time.day) : Date.parse(param)
    rescue ArgumentError
      raise CommandlineError, "option '#{arg}' needs a date"
    end
  end

  ## Print the help message to +stream+.
  def educate stream=$stdout
    width # hack: calculate it now; otherwise we have to be careful not to
          # call this unless the cursor's at the beginning of a line.
    left = {}
    @specs.each do |name, spec|
      left[name] = "--#{spec[:long]}" +
        (spec[:type] == :flag && spec[:default] ? ", --no-#{spec[:long]}" : "") +
        (spec[:short] && spec[:short] != :none ? ", -#{spec[:short]}" : "") +
        case spec[:type]
        when :flag; ""
        when :int; " <i>"
        when :ints; " <i+>"
        when :string; " <s>"
        when :strings; " <s+>"
        when :float; " <f>"
        when :floats; " <f+>"
        when :io; " <filename/uri>"
        when :ios; " <filename/uri+>"
        when :date; " <date>"
        when :dates; " <date+>"
        end
    end

    leftcol_width = left.values.map { |s| s.length }.max || 0
    rightcol_start = leftcol_width + 6 # spaces

    unless @order.size > 0 && @order.first.first == :text
      stream.puts "#@version\n" if @version
      stream.puts "Options:"
    end

    @order.each do |what, opt|
      if what == :text
        stream.puts wrap(opt)
        next
      end

      spec = @specs[opt]
      stream.printf "  %#{leftcol_width}s:   ", left[opt]
      desc = spec[:desc] + begin
        default_s = case spec[:default]
        when $stdout; "<stdout>"
        when $stdin; "<stdin>"
        when $stderr; "<stderr>"
        when Array
          spec[:default].join(", ")
        else
          spec[:default].to_s
        end

        if spec[:default]
          if spec[:desc] =~ /\.$/
            " (Default: #{default_s})"
          else
            " (default: #{default_s})"
          end
        else
          ""
        end
      end
      stream.puts wrap(desc, :width => width - rightcol_start - 1, :prefix => rightcol_start)
    end
  end

  def width #:nodoc:
    @width ||= if $stdout.tty?
      begin
        require 'curses'
        Curses::init_screen
        x = Curses::cols
        Curses::close_screen
        x
      rescue Exception
        80
      end
    else
      80
    end
  end

  def wrap str, opts={} # :nodoc:
    if str == ""
      [""]
    else
      str.split("\n").map { |s| wrap_line s, opts }.flatten
    end
  end

  ## The per-parser version of Trollop::die (see that for documentation).
  def die arg, msg
    if msg
      $stderr.puts "Error: argument --#{@specs[arg][:long]} #{msg}."
    else
      $stderr.puts "Error: #{arg}."
    end
    $stderr.puts "Try --help for help."
    exit(-1)
  end

private

  ## yield successive arg, parameter pairs
  def each_arg args
    remains = []
    i = 0

    until i >= args.length
      if @stop_words.member? args[i]
        remains += args[i .. -1]
        return remains
      end
      case args[i]
      when /^--$/ # arg terminator
        remains += args[(i + 1) .. -1]
        return remains
      when /^--(\S+?)=(.*)$/ # long argument with equals
        yield "--#{$1}", [$2]
        i += 1
      when /^--(\S+)$/ # long argument
        params = collect_argument_parameters(args, i + 1)
        unless params.empty?
          num_params_taken = yield args[i], params
          unless num_params_taken
            if @stop_on_unknown
              remains += args[i + 1 .. -1]
              return remains
            else
              remains += params
            end
          end
          i += 1 + num_params_taken
        else # long argument no parameter
          yield args[i], nil
          i += 1
        end
      when /^-(\S+)$/ # one or more short arguments
        shortargs = $1.split(//)
        shortargs.each_with_index do |a, j|
          if j == (shortargs.length - 1)
            params = collect_argument_parameters(args, i + 1)
            unless params.empty?
              num_params_taken = yield "-#{a}", params
              unless num_params_taken
                if @stop_on_unknown
                  remains += args[i + 1 .. -1]
                  return remains
                else
                  remains += params
                end
              end
              i += 1 + num_params_taken
            else # argument no parameter
              yield "-#{a}", nil
              i += 1
            end
          else
            yield "-#{a}", nil
          end
        end
      else
        if @stop_on_unknown
          remains += args[i .. -1]
          return remains
        else
          remains << args[i]
          i += 1
        end
      end
    end

    remains
  end

  def parse_integer_parameter param, arg
    raise CommandlineError, "option '#{arg}' needs an integer" unless param =~ /^\d+$/
    param.to_i
  end

  def parse_float_parameter param, arg
    raise CommandlineError, "option '#{arg}' needs a floating-point number" unless param =~ FLOAT_RE
    param.to_f
  end

  def parse_io_parameter param, arg
    case param
    when /^(stdin|-)$/i; $stdin
    else
      require 'open-uri'
      begin
        open param
      rescue SystemCallError => e
        raise CommandlineError, "file or url for option '#{arg}' cannot be opened: #{e.message}"
      end
    end
  end

  def collect_argument_parameters args, start_at
    params = []
    pos = start_at
    while args[pos] && args[pos] !~ PARAM_RE && !@stop_words.member?(args[pos]) do
      params << args[pos]
      pos += 1
    end
    params
  end

  def resolve_default_short_options!
    @order.each do |type, name|
      next unless type == :opt
      opts = @specs[name]
      next if opts[:short]

      c = opts[:long].split(//).find { |d| d !~ INVALID_SHORT_ARG_REGEX && !@short.member?(d) }
      if c # found a character to use
        opts[:short] = c
        @short[c] = name
      end
    end
  end

  def wrap_line str, opts={}
    prefix = opts[:prefix] || 0
    width = opts[:width] || (self.width - 1)
    start = 0
    ret = []
    until start > str.length
      nextt =
        if start + width >= str.length
          str.length
        else
          x = str.rindex(/\s/, start + width)
          x = str.index(/\s/, start) if x && x < start
          x || str.length
        end
      ret << (ret.empty? ? "" : " " * prefix) + str[start ... nextt]
      start = nextt + 1
    end
    ret
  end

  ## instance_eval but with ability to handle block arguments
  ## thanks to _why: http://redhanded.hobix.com/inspect/aBlockCostume.html
  def cloaker &b
    (class << self; self; end).class_eval do
      define_method :cloaker_, &b
      meth = instance_method :cloaker_
      remove_method :cloaker_
      meth
    end
  end
end

## The easy, syntactic-sugary entry method into Trollop. Creates a Parser,
## passes the block to it, then parses +args+ with it, handling any errors or
## requests for help or version information appropriately (and then exiting).
## Modifies +args+ in place. Returns a hash of option values.
##
## The block passed in should contain zero or more calls to +opt+
## (Parser#opt), zero or more calls to +text+ (Parser#text), and
## probably a call to +version+ (Parser#version).
##
## The returned block contains a value for every option specified with
## +opt+.  The value will be the value given on the commandline, or the
## default value if the option was not specified on the commandline. For
## every option specified on the commandline, a key "<option
## name>_given" will also be set in the hash.
##
## Example:
##
##   require 'trollop'
##   opts = Trollop::options do
##     opt :monkey, "Use monkey mode"                    # a flag --monkey, defaulting to false
##     opt :name, "Monkey name", :type => :string        # a string --name <s>, defaulting to nil
##     opt :num_limbs, "Number of limbs", :default => 4  # an integer --num-limbs <i>, defaulting to 4
##   end
##
##   ## if called with no arguments
##   p opts # => {:monkey=>false, :name=>nil, :num_limbs=>4, :help=>false}
##
##   ## if called with --monkey
##   p opts # => {:monkey=>true, :name=>nil, :num_limbs=>4, :help=>false, :monkey_given=>true}
##
## See more examples at http://trollop.rubyforge.org.
def options args=ARGV, *a, &b
  @last_parser = Parser.new(*a, &b)
  with_standard_exception_handling(@last_parser) { @last_parser.parse args }
end

## If Trollop::options doesn't do quite what you want, you can create a Parser
## object and call Parser#parse on it. That method will throw CommandlineError,
## HelpNeeded and VersionNeeded exceptions when necessary; if you want to
## have these handled for you in the standard manner (e.g. show the help
## and then exit upon an HelpNeeded exception), call your code from within
## a block passed to this method.
##
## Note that this method will call System#exit after handling an exception!
##
## Usage example:
##
##   require 'trollop'
##   p = Trollop::Parser.new do
##     opt :monkey, "Use monkey mode"                     # a flag --monkey, defaulting to false
##     opt :goat, "Use goat mode", :default => true       # a flag --goat, defaulting to true
##   end
##
##   opts = Trollop::with_standard_exception_handling p do
##     o = p.parse ARGV
##     raise Trollop::HelpNeeded if ARGV.empty? # show help screen
##     o
##   end
##
## Requires passing in the parser object.

def with_standard_exception_handling parser
  begin
    yield
  rescue CommandlineError => e
    $stderr.puts "Error: #{e.message}."
    $stderr.puts "Try --help for help."
    exit(-1)
  rescue HelpNeeded
    parser.educate
    exit
  rescue VersionNeeded
    puts parser.version
    exit
  end
end

## Informs the user that their usage of 'arg' was wrong, as detailed by
## 'msg', and dies. Example:
##
##   options do
##     opt :volume, :default => 0.0
##   end
##
##   die :volume, "too loud" if opts[:volume] > 10.0
##   die :volume, "too soft" if opts[:volume] < 0.1
##
## In the one-argument case, simply print that message, a notice
## about -h, and die. Example:
##
##   options do
##     opt :whatever # ...
##   end
##
##   Trollop::die "need at least one filename" if ARGV.empty?
def die arg, msg=nil
  if @last_parser
    @last_parser.die arg, msg
  else
    raise ArgumentError, "Trollop::die can only be called after Trollop::options"
  end
end

module_function :options, :die, :with_standard_exception_handling

end # module
