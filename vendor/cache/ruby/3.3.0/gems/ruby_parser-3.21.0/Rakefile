# -*- ruby -*-

require "hoe"

Hoe.plugin :seattlerb
Hoe.plugin :racc
Hoe.plugin :isolate
Hoe.plugin :rdoc

Hoe.add_include_dirs "lib"
Hoe.add_include_dirs "../../sexp_processor/dev/lib"
Hoe.add_include_dirs "../../minitest/dev/lib"
Hoe.add_include_dirs "../../oedipus_lex/dev/lib"
Hoe.add_include_dirs "../../ruby2ruby/dev/lib"

V2   = %w[20 21 22 23 24 25 26 27]
V3   = %w[30 31 32 33]

VERS = V2 + V3

ENV["FAST"] = VERS.last if ENV["FAST"] && !VERS.include?(ENV["FAST"])
VERS.replace [ENV["FAST"]] if ENV["FAST"]

racc_flags = nil

Hoe.spec "ruby_parser" do
  developer "Ryan Davis", "ryand-ruby@zenspider.com"

  license "MIT"

  dependency "sexp_processor", "~>  4.16"
  dependency "racc",           "~>  1.5"
  dependency "rake",           [">= 10",  "< 15"], :developer
  dependency "oedipus_lex",    "~>  2.6", :developer

  require_ruby_version [">= 2.6", "< 4"]

  if plugin? :perforce then     # generated files
    VERS.each do |n|
      self.perforce_ignore << "lib/ruby_parser#{n}.rb"
    end

    VERS.each do |n|
      self.perforce_ignore << "lib/ruby_parser#{n}.y"
    end

    self.perforce_ignore << "lib/ruby_lexer.rex.rb"
  end

  if plugin?(:racc)
    self.racc_flags << " -t" if ENV["DEBUG"]
    self.racc_flags << " --superclass RubyParser::Parser"
    racc_flags = self.racc_flags
  end
end

def maybe_add_to_top path, string
  file = File.read path

  return if file.start_with? string

  warn "Altering top of #{path}"
  tmp_path = "#{path}.tmp"
  File.open(tmp_path, "w") do |f|
    f.puts string
    f.puts

    f.write file
    # TODO: make this deal with encoding comments properly?
  end
  File.rename tmp_path, path
end

def unifdef?
  @unifdef ||= system("which unifdef") or abort <<~EOM
    unifdef not found!

    Please install 'unifdef' package on your system or `rake generate` on a mac.
  EOM
end

def racc?
  @racc ||= system("which racc") or abort <<~EOM
    racc not found! `gem install racc`
  EOM
end

generate_parser = proc do |t|
  unifdef?
  racc?
  n = t.name[/\d+/]
  sh "unifdef -tk -DV=%s %s | racc %s /dev/stdin -o %s" % [n, t.source, racc_flags, t.name]
  maybe_add_to_top t.name, "# frozen_string_literal: true"
end

V2.each do |n|
  file "lib/ruby_parser#{n}.rb" => "lib/ruby_parser2.yy", &generate_parser
end

V3.each do |n|
  file "lib/ruby_parser#{n}.rb" => "lib/ruby_parser3.yy", &generate_parser
end

file "lib/ruby_lexer.rex.rb" => "lib/ruby_lexer.rex"

task :generate => [:lexer, :parser]

task :clean do
  rm_rf(Dir["**/*~"] +
        Dir["diff.diff"] + # not all diffs. bit me too many times
        Dir["coverage.info"] +
        Dir["coverage"] +
        Dir["lib/ruby_parser2*.y"] +
        Dir["lib/ruby_parser3*.y"] +
        Dir["lib/*.output"])
end

task :sort do
  sh "grepsort '^ +def' lib/ruby_lexer.rb"
  sh "grepsort '^ +def (test|util)' test/test_ruby_lexer.rb"
end

desc "what was that command again?"
task :huh? do
  puts "ruby #{Hoe::RUBY_FLAGS} bin/ruby_parse -q -g ..."
end

def (task(:phony)).timestamp
  Time.at 0
end

task :isolate => :phony

def dl v, f
  dir = v[/^\d+\.\d+/]
  url = "https://cache.ruby-lang.org/pub/ruby/#{dir}/ruby-#{v}.tar.xz"

  warn "Downloading ruby #{v}"
  system "curl -s -o #{f} #{url}"
end

task :parser => :isolate

multitask :compare_build
task :compare_build => :generate
task :compare => :compare_build

def ruby_parse version
  v         = version[/^\d+\.\d+/].delete "."
  diff      = "compare/diff#{v}.diff"
  rp_txt    = "compare/rp#{v}.txt"
  mri_txt   = "compare/mri#{v}.txt"
  parse_y   = "compare/parse#{v}.y"
  tarball   = "compare/ruby-#{version}.tar.xz"
  ruby_dir  = "compare/ruby-#{version}"
  rp_out    = "lib/ruby_parser#{v}.output"
  rp_y_rb   = "lib/ruby_parser#{v}.rb"
  normalize = "compare/normalize.rb"

  file tarball do
    dl version, tarball
  end

  desc "fetch all tarballs"
  task :fetch => tarball

  file parse_y => tarball do
    extract_glob = case
                   when version > "3.3" then
                     "{id.h,parse.y,tool/{id2token.rb,lrama},defs/id.def}"
                   when version > "3.2" then
                     "{id.h,parse.y,tool/id2token.rb,defs/id.def}"
                   when version > "2.7" then
                     "{id.h,parse.y,tool/{id2token.rb,lib/vpath.rb}}"
                   else
                     "{id.h,parse.y,tool/{id2token.rb,vpath.rb}}"
                   end
    system "tar xf #{tarball} -C compare #{File.basename ruby_dir}/#{extract_glob}"

    # Debugging a new parse build system:
    #
    # Unpack the ruby tarball in question, configure, and run the following:
    #
    # % touch parse.y; make -n parse.c
    # ...
    # echo generating parse.c
    # /Users/ryan/.rubies.current/bin/ruby --disable=gems ./tool/id2token.rb parse.y | \
    #       ruby ./tool/lrama/exe/lrama -oparse.c -Hparse.h - parse.y
    #
    # Then integrate these commands into the mess below:

    d = ruby_dir
    cmd = if version > "3.2" then
            "ruby #{d}/tool/id2token.rb #{d}/parse.y | expand > #{parse_y}"
          else
            "ruby #{d}/tool/id2token.rb --path-separator=.:./ #{d}/id.h #{d}/parse.y | expand | ruby -pe 'gsub(/^%pure-parser/, \"%define api.pure\")'  > #{parse_y}"
          end

    sh cmd

    if File.exist? "#{d}/tool/lrama" then # UGH: this is dumb
      rm_rf "compare/lrama"
      sh "mv #{d}/tool/lrama compare"
    end
    sh "rm -rf #{d}"
  end

  bison = Dir["/opt/homebrew/opt/bison/bin/bison",
              "/usr/local/opt/bison/bin/bison",
              `which bison`.chomp,
             ].first

  file mri_txt => [parse_y, normalize] do
    if version > "3.3" then
      sh "./compare/lrama/exe/lrama -r all -ocompare/parse#{v}.tab.c #{parse_y}"
    else
      sh "#{bison} -r all #{parse_y}"
      mv Dir["parse#{v}.*"], "compare"
    end

    sh "#{normalize} compare/parse#{v}.output > #{mri_txt}"
    rm ["compare/parse#{v}.output", "compare/parse#{v}.tab.c"]
  end

  file rp_out => rp_y_rb

  file rp_txt => [rp_out, normalize] do
    sh "#{normalize} #{rp_out} > #{rp_txt}"
  end

  compare = "compare#{v}"
  compare_build = "compare_build#{v}"

  desc "Compare all grammars to MRI"
  task :compare => compare
  task :compare_build => compare_build

  task compare_build => diff

  file diff => [mri_txt, rp_txt] do
    sh "diff -du #{mri_txt} #{rp_txt} > #{diff}; true"
  end

  desc "Compare #{v} grammar to MRI #{version}"
  task compare => diff do
    system "wc -l #{diff}"
  end

  task :clean do
    rm_f Dir[mri_txt, rp_txt]
  end

  task :realclean do
    rm_f Dir[parse_y, tarball]
  end
end

task :versions do
  require "open-uri"
  require "net/http" # avoid require issues in threads
  require "net/https"

  versions = VERS.map { |s| s.split(//).join "." }

  base_url = "https://cache.ruby-lang.org/pub/ruby"

  class Array
    def human_sort
      sort_by { |item| item.to_s.split(/(\d+)/).map { |e| [e.to_i, e] } }
    end
  end

  versions = versions.map { |ver|
    Thread.new {
      URI
        .parse("#{base_url}/#{ver}/")
        .read
        .scan(/ruby-\d+\.\d+\.\d+[-\w.]*?.tar.gz/)
        .reject { |s| s =~ /-(?:rc|preview)\d/ }
        .human_sort
        .last
        .delete_prefix("ruby-")
        .delete_suffix ".tar.gz"
    }
  }.map(&:value).sort

  puts versions.map { |v| "ruby_parse %p" % [v] }
end

ruby_parse "2.0.0-p648"
ruby_parse "2.1.10"
ruby_parse "2.2.10"
ruby_parse "2.3.8"
ruby_parse "2.4.10"
ruby_parse "2.5.9"
ruby_parse "2.6.10"
ruby_parse "2.7.8"
ruby_parse "3.0.6"
ruby_parse "3.1.4"
ruby_parse "3.2.2"
ruby_parse "3.3.0"

task :debug => :isolate do
  ENV["V"] ||= VERS.last
  Rake.application[:parser].invoke # this way we can have DEBUG set
  Rake.application[:lexer].invoke # this way we can have DEBUG set

  $:.unshift "lib"
  require "ruby_parser"
  require "pp"

  klass = Object.const_get("Ruby#{ENV["V"]}Parser") rescue nil
  raise "Unsupported version #{ENV["V"]}" unless klass
  parser = klass.new

  time = (ENV["RP_TIMEOUT"] || 10).to_i

  n = ENV["BUG"]
  file = (n && "bug#{n}.rb") || ENV["F"] || ENV["FILE"] || "debug.rb"
  ruby = ENV["R"] || ENV["RUBY"]

  if ruby then
    file = "env"
  else
    ruby = File.read file
  end


  begin
    pp parser.process(ruby, file, time)
  rescue ArgumentError, Racc::ParseError => e
    p e
    puts e.backtrace.join "\n  "
    ss = parser.lexer.ss
    src = ss.string
    lines = src[0..ss.pos].split(/\n/)
    abort "on #{file}:#{lines.size}"
  end
end

task :debug3 do
  file    = ENV["F"] || "debug.rb"
  version = ENV["V"] || ""
  verbose = ENV["VERBOSE"] ? "-v" : ""
  munge    = "./tools/munge.rb #{verbose}"

  abort "Need a file to parse, via: F=path.rb" unless file

  ENV.delete "V"

  ruby = "ruby#{version}"

  sh "#{ruby} -v"
  sh "#{ruby} -y #{file} 2>&1 | #{munge} > tmp/ruby"
  sh "#{ruby} ./tools/ripper.rb -d #{file} | #{munge} > tmp/rip"
  sh "rake debug F=#{file} DEBUG=1 2>&1 | #{munge} > tmp/rp"
  sh "diff -U 999 -d tmp/{ruby,rp}"
end

task :cmp do
  sh %(emacsclient --eval '(ediff-files "tmp/ruby" "tmp/rp")')
end

task :cmp3 do
  sh %(emacsclient --eval '(ediff-files3 "tmp/ruby" "tmp/rip" "tmp/rp")')
end

task :extract => :isolate do
  ENV["V"] ||= VERS.last
  Rake.application[:parser].invoke # this way we can have DEBUG set

  file = ENV["F"] || ENV["FILE"] || abort("Need to provide F=<path>")

  ruby "-Ilib", "bin/ruby_parse_extract_error", file
end

task :parse => :isolate do
  ENV["V"] ||= VERS.last
  Rake.application[:parser].invoke # this way we can have DEBUG set

  file = ENV["F"] || ENV["FILE"] || abort("Need to provide F=<path>")

  ruby "-Ilib", "bin/ruby_parse", file
end

task :bugs do
  sh "for f in bug*.rb bad*.rb ; do #{Gem.ruby} -S rake debug F=$f && rm $f ; done"
end

# vim: syntax=Ruby
