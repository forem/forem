# Generates available username based on
# multiple generators in the following order:
#   * list of supplied usernames
#   * list of supplied usernames with suffix
#   * random generated letters
#
# @todo Extract username validation in separate class
module Users
  class UsernameGenerator
    def self.call(...)
      new(...).call
    end

    # @param list [Array<String>] a list of usernames
    def initialize(list = [])
      @list = list
    end

    def call
      from_list(modified_list) || from_list(list_with_suffix) || from_list(Array.new(3) { random_letters })
    end

    private

    def from_list(list)
      list.detect { |username| !username_exists?(username) }
    end

    def username_exists?(username)
      User.exists?(username: username) ||
        Organization.exists?(slug: username) ||
        Page.exists?(slug: username) ||
        Podcast.exists?(slug: username)
    end

    def filtered_list
      @list.select { |s| s.is_a?(String) && s.present? }
    end

    def modified_list
      filtered_list.map { |s| s.downcase.gsub(/[^0-9a-z_]/i, "").delete(" ") }
    end

    def list_with_suffix
      modified_list.map { |s| [s, rand(100)].join("_") }
    end

    def random_letters
      ("a".."z").to_a.sample(12).join
    end
  end
end
