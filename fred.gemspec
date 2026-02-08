require_relative "lib/fred/version"

Gem::Specification.new do |spec|
  spec.name = "fred"
  spec.version = FRED::VERSION
  spec.authors = ["William T. Nelson"]
  spec.email = ["35801+wtn@users.noreply.github.com"]

  spec.summary = "FRED"
  spec.homepage = "https://github.com/wtn/fred"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "async-http"
  spec.add_dependency "async-limiter", "~> 2.0"
  spec.add_dependency "timeseries", ">= 1.0.0.pre"
end
