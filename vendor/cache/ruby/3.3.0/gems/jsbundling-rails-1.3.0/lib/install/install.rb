say "Compile into app/assets/builds"
empty_directory "app/assets/builds"
keep_file "app/assets/builds"

if (sprockets_manifest_path = Rails.root.join("app/assets/config/manifest.js")).exist?
  append_to_file sprockets_manifest_path, %(//= link_tree ../builds\n)
end

if Rails.root.join(".gitignore").exist?
  append_to_file(".gitignore", %(\n/app/assets/builds/*\n!/app/assets/builds/.keep\n))
  append_to_file(".gitignore", %(\n/node_modules\n))
end

if (app_layout_path = Rails.root.join("app/views/layouts/application.html.erb")).exist?
  say "Add JavaScript include tag in application layout"
  insert_into_file app_layout_path.to_s,
    %(\n    <%= javascript_include_tag "application", "data-turbo-track": "reload", type: "module" %>), before: /\s*<\/head>/
else
  say "Default application.html.erb is missing!", :red
  say %(        Add <%= javascript_include_tag "application", "data-turbo-track": "reload", type: "module" %> within the <head> tag in your custom layout.)
end

unless (app_js_entrypoint_path = Rails.root.join("app/javascript/application.js")).exist?
  say "Create default entrypoint in app/javascript/application.js"
  empty_directory app_js_entrypoint_path.parent.to_s
  copy_file "#{__dir__}/application.js", app_js_entrypoint_path
end

unless Rails.root.join("package.json").exist?
  say "Add default package.json"
  copy_file "#{__dir__}/package.json", "package.json"
end

say "Add bin/dev to start foreman"
copy_file "#{__dir__}/dev", "bin/dev"
chmod "bin/dev", 0755, verbose: false
