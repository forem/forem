class LanguageDetector
  def initialize(article)
    @article = article
  end

  def detect
    response = get_language
    response[:code] if response[:reliable]
  rescue StandardError
    nil
  end

  def get_language
    CLD.detect_language(text)
  end

  def text
    "#{@article.title}. #{FrontMatterParser::Parser.new(:md).call(@article.body_markdown).content.split('`')[0]}"
  end
end
