#encoding: UTF-8

# This class represents the INI file and can be used to parse, modify,
# and write INI files.
class IniFile
  include Enumerable

  class Error < StandardError; end
  VERSION = '3.0.0'

  # Public: Open an INI file and load the contents.
  #
  # filename - The name of the file as a String
  # opts     - The Hash of options (default: {})
  #            :comment   - String containing the comment character(s)
  #            :parameter - String used to separate parameter and value
  #            :encoding  - Encoding String for reading / writing
  #            :default   - The String name of the default global section
  #
  # Examples
  #
  #   IniFile.load('file.ini')
  #   #=> IniFile instance
  #
  #   IniFile.load('does/not/exist.ini')
  #   #=> nil
  #
  # Returns an IniFile instance or nil if the file could not be opened.
  def self.load( filename, opts = {} )
    return unless File.file? filename
    new(opts.merge(:filename => filename))
  end

  # Get and set the filename
  attr_accessor :filename

  # Get and set the encoding
  attr_accessor :encoding

  # Public: Create a new INI file from the given set of options. If :content
  # is provided then it will be used to populate the INI file. If a :filename
  # is provided then the contents of the file will be parsed and stored in the
  # INI file. If neither the :content or :filename is provided then an empty
  # INI file is created.
  #
  # opts - The Hash of options (default: {})
  #   :content   - The String/Hash containing the INI contents
  #   :comment   - String containing the comment character(s)
  #   :parameter - String used to separate parameter and value
  #   :encoding  - Encoding String for reading / writing
  #   :default   - The String name of the default global section
  #   :filename  - The filename as a String
  #
  # Examples
  #
  #   IniFile.new
  #   #=> an empty IniFile instance
  #
  #   IniFile.new( :content => "[global]\nfoo=bar" )
  #   #=> an IniFile instance
  #
  #   IniFile.new( :filename => 'file.ini', :encoding => 'UTF-8' )
  #   #=> an IniFile instance
  #
  #   IniFile.new( :content => "[global]\nfoo=bar", :comment => '#' )
  #   #=> an IniFile instance
  #
  def initialize( opts = {} )
    @comment  = opts.fetch(:comment, ';#')
    @param    = opts.fetch(:parameter, '=')
    @encoding = opts.fetch(:encoding, nil)
    @default  = opts.fetch(:default, 'global')
    @filename = opts.fetch(:filename, nil)
    content   = opts.fetch(:content, nil)

    @ini = Hash.new {|h,k| h[k] = Hash.new}

    if    content.is_a?(Hash) then merge!(content)
    elsif content             then parse(content)
    elsif @filename           then read
    end
  end

  # Public: Write the contents of this IniFile to the file system. If left
  # unspecified, the currently configured filename and encoding will be used.
  # Otherwise the filename and encoding can be specified in the options hash.
  #
  # opts - The default options Hash
  #        :filename - The filename as a String
  #        :encoding - The encoding as a String
  #
  # Returns this IniFile instance.
  def write( opts = {} )
    filename = opts.fetch(:filename, @filename)
    encoding = opts.fetch(:encoding, @encoding)
    mode = encoding ? "w:#{encoding}" : "w"

    File.open(filename, mode) do |f|
      @ini.each do |section,hash|
        f.puts "[#{section}]"
        hash.each {|param,val| f.puts "#{param} #{@param} #{escape_value val}"}
        f.puts
      end
    end

    self
  end
  alias :save :write

  # Public: Read the contents of the INI file from the file system and replace
  # and set the state of this IniFile instance. If left unspecified the
  # currently configured filename and encoding will be used when reading from
  # the file system. Otherwise the filename and encoding can be specified in
  # the options hash.
  #
  # opts - The default options Hash
  #        :filename - The filename as a String
  #        :encoding - The encoding as a String
  #
  # Returns this IniFile instance if the read was successful; nil is returned
  # if the file could not be read.
  def read( opts = {} )
    filename = opts.fetch(:filename, @filename)
    encoding = opts.fetch(:encoding, @encoding)
    return unless File.file? filename

    mode = encoding ? "r:#{encoding}" : "r"
    File.open(filename, mode) { |fd| parse fd }
    self
  end
  alias :restore :read

  # Returns this IniFile converted to a String.
  def to_s
    s = []
    @ini.each do |section,hash|
      s << "[#{section}]"
      hash.each {|param,val| s << "#{param} #{@param} #{escape_value val}"}
      s << ""
    end
    s.join("\n")
  end

  # Returns this IniFile converted to a Hash.
  def to_h
    @ini.dup
  end

  # Public: Creates a copy of this inifile with the entries from the
  # other_inifile merged into the copy.
  #
  # other - The other IniFile.
  #
  # Returns a new IniFile.
  def merge( other )
    self.dup.merge!(other)
  end

  # Public: Merges other_inifile into this inifile, overwriting existing
  # entries. Useful for having a system inifile with user overridable settings
  # elsewhere.
  #
  # other - The other IniFile.
  #
  # Returns this IniFile.
  def merge!( other )
    return self if other.nil?

    my_keys = @ini.keys
    other_keys = case other
      when IniFile
        other.instance_variable_get(:@ini).keys
      when Hash
        other.keys
      else
        raise Error, "cannot merge contents from '#{other.class.name}'"
      end

    (my_keys & other_keys).each do |key|
      case other[key]
      when Hash
        @ini[key].merge!(other[key])
      when nil
        nil
      else
        raise Error, "cannot merge section #{key.inspect} - unsupported type: #{other[key].class.name}"
      end
    end

    (other_keys - my_keys).each do |key|
      @ini[key] = case other[key]
        when Hash
          other[key].dup
        when nil
          {}
        else
          raise Error, "cannot merge section #{key.inspect} - unsupported type: #{other[key].class.name}"
        end
    end

    self
  end

  # Public: Yield each INI file section, parameter, and value in turn to the
  # given block.
  #
  # block - The block that will be iterated by the each method. The block will
  #         be passed the current section and the parameter/value pair.
  #
  # Examples
  #
  #   inifile.each do |section, parameter, value|
  #     puts "#{parameter} = #{value} [in section - #{section}]"
  #   end
  #
  # Returns this IniFile.
  def each
    return unless block_given?
    @ini.each do |section,hash|
      hash.each do |param,val|
        yield section, param, val
      end
    end
    self
  end

  # Public: Yield each section in turn to the given block.
  #
  # block - The block that will be iterated by the each method. The block will
  #         be passed the current section as a Hash.
  #
  # Examples
  #
  #   inifile.each_section do |section|
  #     puts section.inspect
  #   end
  #
  # Returns this IniFile.
  def each_section
    return unless block_given?
    @ini.each_key {|section| yield section}
    self
  end

  # Public: Remove a section identified by name from the IniFile.
  #
  # section - The section name as a String.
  #
  # Returns the deleted section Hash.
  def delete_section( section )
    @ini.delete section.to_s
  end

  # Public: Get the section Hash by name. If the section does not exist, then
  # it will be created.
  #
  # section - The section name as a String.
  #
  # Examples
  #
  #   inifile['global']
  #   #=> global section Hash
  #
  # Returns the Hash of parameter/value pairs for this section.
  def []( section )
    return nil if section.nil?
    @ini[section.to_s]
  end

  # Public: Set the section to a hash of parameter/value pairs.
  #
  # section - The section name as a String.
  # value   - The Hash of parameter/value pairs.
  #
  # Examples
  #
  #   inifile['tenderloin'] = { 'gritty' => 'yes' }
  #   #=> { 'gritty' => 'yes' }
  #
  # Returns the value Hash.
  def []=( section, value )
    @ini[section.to_s] = value
  end

  # Public: Create a Hash containing only those INI file sections whose names
  # match the given regular expression.
  #
  # regex - The Regexp used to match section names.
  #
  # Examples
  #
  #   inifile.match(/^tree_/)
  #   #=> Hash of matching sections
  #
  # Return a Hash containing only those sections that match the given regular
  # expression.
  def match( regex )
    @ini.dup.delete_if { |section, _| section !~ regex }
  end

  # Public: Check to see if the IniFile contains the section.
  #
  # section - The section name as a String.
  #
  # Returns true if the section exists in the IniFile.
  def has_section?( section )
    @ini.has_key? section.to_s
  end

  # Returns an Array of section names contained in this IniFile.
  def sections
    @ini.keys
  end

  # Public: Freeze the state of this IniFile object. Any attempts to change
  # the object will raise an error.
  #
  # Returns this IniFile.
  def freeze
    super
    @ini.each_value {|h| h.freeze}
    @ini.freeze
    self
  end

  # Public: Mark this IniFile as tainted -- this will traverse each section
  # marking each as tainted.
  #
  # Returns this IniFile.
  def taint
    super
    @ini.each_value {|h| h.taint}
    @ini.taint
    self
  end

  # Public: Produces a duplicate of this IniFile. The duplicate is independent
  # of the original -- i.e. the duplicate can be modified without changing the
  # original. The tainted state of the original is copied to the duplicate.
  #
  # Returns a new IniFile.
  def dup
    other = super
    other.instance_variable_set(:@ini, Hash.new {|h,k| h[k] = Hash.new})
    @ini.each_pair {|s,h| other[s].merge! h}
    other.taint if self.tainted?
    other
  end

  # Public: Produces a duplicate of this IniFile. The duplicate is independent
  # of the original -- i.e. the duplicate can be modified without changing the
  # original. The tainted state and the frozen state of the original is copied
  # to the duplicate.
  #
  # Returns a new IniFile.
  def clone
    other = dup
    other.freeze if self.frozen?
    other
  end

  # Public: Compare this IniFile to some other IniFile. For two INI files to
  # be equivalent, they must have the same sections with the same parameter /
  # value pairs in each section.
  #
  # other - The other IniFile.
  #
  # Returns true if the INI files are equivalent and false if they differ.
  def eql?( other )
    return true if equal? other
    return false unless other.instance_of? self.class
    @ini == other.instance_variable_get(:@ini)
  end
  alias :== :eql?

  # Escape special characters.
  #
  # value - The String value to escape.
  #
  # Returns the escaped value.
  def escape_value( value )
    value = value.to_s.dup
    value.gsub!(%r/\\([0nrt])/, '\\\\\1')
    value.gsub!(%r/\n/, '\n')
    value.gsub!(%r/\r/, '\r')
    value.gsub!(%r/\t/, '\t')
    value.gsub!(%r/\0/, '\0')
    value
  end

  # Parse the given content and store the information in this IniFile
  # instance. All data will be cleared out and replaced with the information
  # read from the content.
  #
  # content - A String or a file descriptor (must respond to `each_line`)
  #
  # Returns this IniFile.
  def parse( content )
    parser = Parser.new(@ini, @param, @comment, @default)
    parser.parse(content)
    self
  end

  # The IniFile::Parser has the responsibility of reading the contents of an
  # .ini file and storing that information into a ruby Hash. The object being
  # parsed must respond to `each_line` - this includes Strings and any IO
  # object.
  class Parser

    attr_writer :section
    attr_accessor :property
    attr_accessor :value

    # Create a new IniFile::Parser that can be used to parse the contents of
    # an .ini file.
    #
    # hash    - The Hash where parsed information will be stored
    # param   - String used to separate parameter and value
    # comment - String containing the comment character(s)
    # default - The String name of the default global section
    #
    def initialize( hash, param, comment, default )
      @hash = hash
      @default = default

      comment = comment.to_s.empty? ? "\\z" : "\\s*(?:[#{comment}].*)?\\z"

      @section_regexp  = %r/\A\s*\[([^\]]+)\]#{comment}/
      @ignore_regexp   = %r/\A#{comment}/
      @property_regexp = %r/\A(.*?)(?<!\\)#{param}(.*)\z/

      @open_quote      = %r/\A\s*(".*)\z/
      @close_quote     = %r/\A(.*(?<!\\)")#{comment}/
      @full_quote      = %r/\A\s*(".*(?<!\\)")#{comment}/
      @trailing_slash  = %r/\A(.*)(?<!\\)\\#{comment}/
      @normal_value    = %r/\A(.*?)#{comment}/
    end

    # Returns `true` if the current value starts with a leading double quote.
    # Otherwise returns false.
    def leading_quote?
      value && value =~ %r/\A"/
    end

    # Given a string, attempt to parse out a value from that string. This
    # value might be continued on the following line. So this method returns
    # `true` if it is expecting more data.
    #
    # string - String to parse
    #
    # Returns `true` if the next line is also part of the current value.
    # Returns `fase` if the string contained a complete value.
    def parse_value( string )
      continuation = false

      # if our value starts with a double quote, then we are in a
      # line continuation situation
      if leading_quote?
        # check for a closing quote at the end of the string
        if string =~ @close_quote
          value << $1

        # otherwise just append the string to the value
        else
          value << string
          continuation = true
        end

      # not currently processing a continuation line
      else
        case string
        when @full_quote
          self.value = $1

        when @open_quote
          self.value = $1
          continuation = true

        when @trailing_slash
          self.value ?  self.value << $1 : self.value = $1
          continuation = true

        when @normal_value
          self.value ?  self.value << $1 : self.value = $1

        else
          error
        end
      end

      if continuation
        self.value << $/ if leading_quote?
      else
        process_property
      end

      continuation
    end

    # Parse the ini file contents. This will clear any values currently stored
    # in the ini hash.
    #
    # content - Any object that responds to `each_line`
    #
    # Returns nil.
    def parse( content )
      return unless content

      continuation = false

      @hash.clear
      @line = nil
      self.section = nil

      content.each_line do |line|
        @line = line.chomp

        if continuation
          continuation = parse_value @line
        else
          case @line
          when @ignore_regexp
            nil
          when @section_regexp
            self.section = @hash[$1]
          when @property_regexp
            self.property = $1.strip
            error if property.empty?

            continuation = parse_value $2
          else
            error
          end
        end
      end

      # check here if we have a dangling value ... usually means we have an
      # unmatched open quote
      if leading_quote?
        error "Unmatched open quote"
      elsif property && value
        process_property
      elsif value
        error
      end

      nil
    end

    # Store the property/value pair in the currently active section. This
    # method checks for continuation of the value to the next line.
    #
    # Returns nil.
    def process_property
      property.strip!
      value.strip!

      self.value = $1 if value =~ %r/\A"(.*)(?<!\\)"\z/m

      section[property] = typecast(value)

      self.property = nil
      self.value = nil
    end

    # Returns the current section Hash.
    def section
      @section ||= @hash[@default]
    end

    # Raise a parse error using the given message and appending the current line
    # being parsed.
    #
    # msg - The message String to use.
    #
    # Raises IniFile::Error
    def error( msg = 'Could not parse line' )
      raise Error, "#{msg}: #{@line.inspect}"
    end

    # Attempt to typecast the value string. We are looking for boolean values,
    # integers, floats, and empty strings. Below is how each gets cast, but it
    # is pretty logical and straightforward.
    #
    #  "true"  -->  true
    #  "false" -->  false
    #  ""      -->  nil
    #  "42"    -->  42
    #  "3.14"  -->  3.14
    #  "foo"   -->  "foo"
    #
    # Returns the typecast value.
    def typecast( value )
      case value
      when %r/\Atrue\z/i;  true
      when %r/\Afalse\z/i; false
      when %r/\A\s*\z/i;   nil
      else
        Integer(value) rescue \
        Float(value)   rescue \
        unescape_value(value)
      end
    end

    # Unescape special characters found in the value string. This will convert
    # escaped null, tab, carriage return, newline, and backslash into their
    # literal equivalents.
    #
    # value - The String value to unescape.
    #
    # Returns the unescaped value.
    def unescape_value( value )
      value = value.to_s
      value.gsub!(%r/\\[0nrt\\]/) { |char|
        case char
        when '\0';   "\0"
        when '\n';   "\n"
        when '\r';   "\r"
        when '\t';   "\t"
        when '\\\\'; "\\"
        end
      }
      value
    end
  end

end  # IniFile

