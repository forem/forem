module ErrorMessages
  class Clean
    FRONTMATTER_ERROR = /expected key while parsing a block mapping at line/.freeze

    REPLACEMENT_ERROR = "There was a problem parsing the front-matter YAML. " \
      "Perhaps you need to escape a quote or a colon or something. " \
      "Email %s if you are having trouble.".freeze

    def self.call(error_message)
      return error_message unless error_message.match?(FRONTMATTER_ERROR)

      format(REPLACEMENT_ERROR, ForemInstance.email)
    end
  end
end
