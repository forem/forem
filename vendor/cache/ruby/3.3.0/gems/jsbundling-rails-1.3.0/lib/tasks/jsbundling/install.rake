namespace :javascript do
  namespace :install do
    desc "Install Bun"
    task :bun do
      system "#{RbConfig.ruby} ./bin/rails app:template LOCATION=#{File.expand_path("../../install/bun/install.rb",  __dir__)}"
    end

    desc "Install esbuild"
    task :esbuild do
      system "#{RbConfig.ruby} ./bin/rails app:template LOCATION=#{File.expand_path("../../install/esbuild/install.rb",  __dir__)}"
    end

    desc "Install rollup.js"
    task :rollup do
      system "#{RbConfig.ruby} ./bin/rails app:template LOCATION=#{File.expand_path("../../install/rollup/install.rb",  __dir__)}"
    end

    desc "Install Webpack"
    task :webpack do
      system "#{RbConfig.ruby} ./bin/rails app:template LOCATION=#{File.expand_path("../../install/webpack/install.rb",  __dir__)}"
    end
  end
end
