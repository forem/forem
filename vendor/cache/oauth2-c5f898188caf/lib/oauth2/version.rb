module OAuth2
  module Version
  module_function

    # The major version
    #
    # @return [Integer]
    def major
      1
    end

    # The minor version
    #
    # @return [Integer]
    def minor
      4
    end

    # The patch version
    #
    # @return [Integer]
    def patch
      3
    end

    # The pre-release version, if any
    #
    # @return [Integer, NilClass]
    def pre
      nil
    end

    # The version number as a hash
    #
    # @return [Hash]
    def to_h
      {
        :major => major,
        :minor => minor,
        :patch => patch,
        :pre => pre,
      }
    end

    # The version number as an array
    #
    # @return [Array]
    def to_a
      [major, minor, patch, pre].compact
    end

    # The version number as a string
    #
    # @return [String]
    def to_s
      to_a.join('.')
    end
  end
end
