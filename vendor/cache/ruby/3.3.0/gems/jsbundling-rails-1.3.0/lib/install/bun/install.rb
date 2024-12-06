require 'json'

apply "#{__dir__}/../install.rb"

if Rails.root.join("Procfile.dev").exist?
  append_to_file "Procfile.dev", "js: bun run build --watch\n"
else
  say "Add default Procfile.dev"
  copy_file "#{__dir__}/Procfile.dev", "Procfile.dev"

  say "Ensure foreman is installed"
  run "gem install foreman"
end

say "Add default bun.config.js"
copy_file "#{__dir__}/bun.config.js", "bun.config.js"

say "Add build script to package.json"
package_json = JSON.parse(File.read("package.json"))
package_json["scripts"] ||= {}
package_json["scripts"]["build"] = "bun bun.config.js"
File.write("package.json", JSON.pretty_generate(package_json))

say "Add ability to diff lockb to .gitattributes"
if Rails.root.join(".gitattributes").exist?
  append_to_file ".gitattributes", "\n# See https://bun.sh/docs/install/lockfile\n*.lockb diff=lockb\n"
else
  copy_file "#{__dir__}/.gitattributes", ".gitattributes"
end
say %(Run `git config diff.lockb.textconv bun && git config diff.lockb.binary true` to enable pretty diffs for Bun's .lockb file), :green
