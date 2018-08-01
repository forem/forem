ENVied.require(*ENV['ENVIED_GROUPS'] || Rails.groups)

class ApplicationConfig
  def self.[](key)
    ENVied.send(key)
  end
end
