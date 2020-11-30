class ErrorMessageCleaner
  attr_accessor :error_message

  def initialize(error_message)
    @error_message = error_message
  end

  def clean
    if error_message.include?("expected key while parsing a block mapping at line")
      "There was a problem parsing the front-matter YAML. Perhaps you need to escape a quote " \
      "or a colon or something. Email #{SiteConfig.email_addresses[:contact]} if you are having trouble."
    else
      error_message
    end
  end
end
