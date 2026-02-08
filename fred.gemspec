require_relative 'lib/fred/version'

Gem::Specification.new do |spec|
  spec.name = 'fred'
  spec.version = Fred::VERSION
  spec.authors = ['Johnny Khai Nguyen']
  spec.email = ['johnnyn@gmail.com']

  spec.summary = 'Ruby wrapper for the St. Louis Federal Reserve FRED API'
  spec.homepage = 'https://github.com/phuphighter/fred'
  spec.license = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'httparty'
  spec.add_dependency 'hashie', '~> 5.0'
end
