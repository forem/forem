class ApplicationConfig
  def self.[](key)
    ENVied.send(key)
  end
end
