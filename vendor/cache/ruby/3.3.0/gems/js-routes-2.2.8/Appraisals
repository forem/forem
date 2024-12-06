def define_appraisal(rails, version, sprockets)
  sprockets.each do |sprocket|
    appraise "#{rails}-sprockets-#{sprocket}" do
      gem "railties", "~> #{version}"
      gem "sprockets", "~> #{sprocket}.0"
    end
  end
end

[
  [:rails50, '5.0.5',  [3]],
  [:rails51, '5.1.3',  [3]],
  [:rails52, '5.2.3',  [3]],
  [:rails70, '7.0.3.1', [4]]
].each do |name, version, sprockets|
  define_appraisal(name, version, sprockets)
end
