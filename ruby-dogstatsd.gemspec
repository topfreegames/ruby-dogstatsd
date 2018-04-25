# coding: utf-8

Gem::Specification.new do |spec|
    spec.name          = "ruby-dogstatsd"
    spec.version       = "0.0.3"
    spec.authors       = ["Top Free Games"]
    spec.email         = ["backend@tfgco.com"]
    spec.description   = %q{Rails middleware report metrics to Datadog}
    spec.summary       = %q{Report basic metrics to datadog}
    spec.homepage      = "https://git.topfreegames.com/topfreegames/rails-datadog-middleware"
    spec.license       = "MIT"
  
    spec.files         = `git ls-files`.split($/)
    spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
    spec.test_files    = spec.files.grep(%r{^(spec)/})
    spec.require_paths = ["lib"]
  
    spec.add_runtime_dependency(%q<dogstatsd-ruby>, ">= 2.0.0")
    spec.add_runtime_dependency(%q<sidekiq>)

    spec.add_development_dependency(%q<rake>)
    spec.add_development_dependency(%q<rack>)
    spec.add_development_dependency(%q<bundler>)
    spec.add_development_dependency(%q<rspec>, "~> 3.0")
    spec.add_development_dependency(%q<sidekiq>)
  end
