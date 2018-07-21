class ApplicationConfig
  def self.[](key)
    ENVied.send(key)
  end

  def self.[]=(key, value)
    ENV[key] = value
  end
end
