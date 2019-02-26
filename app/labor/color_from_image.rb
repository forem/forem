class ColorFromImage
  def initialize(url)
    @url = url
  end

  def main
    return "#000000" unless Rails.env.production?

    begin
      get_palette["colors"][0]["hex"]
    rescue StandardError
      "#dddddd"
    end
  end

  def get_palette
    input = {
      url: @url
    }
    client = Algorithmia.client(ApplicationConfig["ALGORITHMIA_KEY"])
    algo = client.algo("vagrant/ColorSchemeExtraction/0.2.0")
    algo.pipe(input).result
  end
end
