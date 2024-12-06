require 'easy_translate/detection'
require 'easy_translate/translation'
require 'easy_translate/translation_target'

module EasyTranslate

  autoload :EasyTranslateException, 'easy_translate/easy_translate_exception'
  autoload :Request, 'easy_translate/request'

  autoload :LANGUAGES, 'easy_translate/languages'
  autoload :VERSION, 'easy_translate/version'

  extend Detection # Language Detection
  extend Translation # Language Translation
  extend TranslationTarget # Language Translation Targets

  class << self
    attr_accessor :api_key
  end

end
