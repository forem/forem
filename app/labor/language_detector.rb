class LanguageDetector

  def initialize(article)
    @article = article
  end

  def detect
    begin
      response = get_language
      response["result"] if response["confidence"] > 0.8
    rescue
      nil
    end
  end

  def get_language
    return { "result" => "en", "confidence" => 0.9 } unless Rails.env.production?
    client = Algorithmia.client(ApplicationConfig["ALGORITHMIA_KEY"])
    algo = client.algo('miguelher/LanguageDetector/0.1.0')
    algo.pipe(text).result
  end

  def text
    @article.title + "\n" +
      non_default_description.to_s +
      FrontMatterParser::Parser.new(:md).call(@article.body_markdown).content.split("`")[0]
  end

  def non_default_description
    @article.description + "\n" unless @article.description.include? "From the DEV community"
  end
end
