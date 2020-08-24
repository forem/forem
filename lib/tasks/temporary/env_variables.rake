# Create a .env file from your application.yml file
task create_dot_env_file: :environment do
  exit if File.file?(".env")

  # Used to set all defaults we have if not set already in application.yml
  sample_app_yml = YAML.load_file("config/sample_application.yml")

  # read existing lines
  application_yml = File.open("config/application.yml", "r").read

  File.open(".env", "w") do |env_file|
    # add default values only if they are not already present in the
    # application.yml file which would result in a duplicate key
    sample_app_yml.each_pair do |variable, value|
      env_file.write("export #{variable}=#{value}\n") unless application_yml.include?(variable.to_s)
    end

    File.open("config/application.yml", "r") do |file|
      file.each_line do |line|
        new_line = line.gsub(": ", "=")
        unless new_line.blank? || new_line.starts_with?("#")
          new_line.prepend("export ")
        end
        env_file.write(new_line)
      end
    end
  end
end
