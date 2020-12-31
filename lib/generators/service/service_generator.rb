class ServiceGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  argument :arguments, type: :array, default: [], banner: "arguments for .call"
  class_option :spec, type: :boolean, default: true

  def create_service_file
    template(
      "service.erb",
      File.join("app/services", class_path, "#{file_name}.rb"),
    )

    return unless options["spec"]

    template(
      "service_spec.erb",
      File.join("spec/services", class_path, "#{file_name}_spec.rb"),
    )
  end

  def signature
    @signature ||= arguments.present? ? "(#{arguments.join(', ')})" : nil
  end
end
