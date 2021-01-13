module Articles
  class DetectLanguage
    def self.call(article)
      text = extract_text(article)
      response = CLD.detect_language(text)
      response[:code] if response[:reliable]
    rescue StandardError
      nil
    end

    def self.extract_text(article)
      parsed = FrontMatterParser::Parser.new(:md).call(article.body_markdown).content.split("`")[0]
      "#{article.title}. #{parsed}"
    end
    private_class_method :extract_text
  end
end
