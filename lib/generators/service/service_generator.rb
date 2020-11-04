class ServiceGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  argument :arguments, type: :array, default: [], banner: "arguments for .call"
  class_option :module, type: :string, desc: "Containing module for the service"
  class_option :specs, type: :boolean, default: true

  def create_service_file
    service_dir = Pathname.new("app/services").join(module_name)
    FileUtils.mkdir_p(service_dir) unless Dir.exist?(service_dir)

    template("service.erb", service_dir.join("#{file_name}.rb"))
  end

  def module_name
    @module_name ||= options[:module].to_s.downcase
  end

  def signature
    @signature ||= arguments.present? ? "(#{arguments.join(', ')})" : nil
  end
end
