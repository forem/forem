# encoding: utf-8
Gem::Specification.new do |s|
  s.name = 'redcarpet'
  s.version = '3.6.0'
  s.summary = "Markdown that smells nice"
  s.description = 'A fast, safe and extensible Markdown to (X)HTML parser'
  s.date = '2023-01-29'
  s.email = 'vicent@github.com'
  s.homepage = 'https://github.com/vmg/redcarpet'
  s.authors = ["Natacha Porté", "Vicent Martí"]
  s.license = 'MIT'
  s.required_ruby_version = '>= 1.9.2'
  # = MANIFEST =
  s.files = %w[
    CHANGELOG.md
    CONTRIBUTING.md
    COPYING
    Gemfile
    README.markdown
    Rakefile
    bin/redcarpet
    ext/redcarpet/autolink.c
    ext/redcarpet/autolink.h
    ext/redcarpet/buffer.c
    ext/redcarpet/buffer.h
    ext/redcarpet/extconf.rb
    ext/redcarpet/houdini.h
    ext/redcarpet/houdini_href_e.c
    ext/redcarpet/houdini_html_e.c
    ext/redcarpet/html.c
    ext/redcarpet/html.h
    ext/redcarpet/html_block_names.txt
    ext/redcarpet/html_blocks.h
    ext/redcarpet/html_smartypants.c
    ext/redcarpet/markdown.c
    ext/redcarpet/markdown.h
    ext/redcarpet/rc_markdown.c
    ext/redcarpet/rc_render.c
    ext/redcarpet/redcarpet.h
    ext/redcarpet/stack.c
    ext/redcarpet/stack.h
    lib/redcarpet.rb
    lib/redcarpet/cli.rb
    lib/redcarpet/compat.rb
    lib/redcarpet/render_man.rb
    lib/redcarpet/render_strip.rb
    redcarpet.gemspec
  ]
  # = MANIFEST =
  s.test_files = s.files.grep(%r{^test/})
  s.extra_rdoc_files = ["COPYING"]
  s.extensions = ["ext/redcarpet/extconf.rb"]
  s.executables = ["redcarpet"]
  s.require_paths = ["lib"]

  s.add_development_dependency "rake", "~> 13"
  s.add_development_dependency "rake-compiler", "~> 1.1"
  s.add_development_dependency "test-unit", "~> 3.5"
end
