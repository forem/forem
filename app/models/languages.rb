module Languages
  LIST = { "en" => "English", "ja" => "Japanese", "es" => "Spanish", "fr" => "French", "it" => "Italian", "pt" => "Portuguese" }.freeze

  module_function

  def available?(code)
    LIST.key? code
  end
end
