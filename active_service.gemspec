require_relative "lib/active_service/version"

Gem::Specification.new do |spec|
  spec.name = "active_service"
  spec.version = ActiveService::VERSION
  spec.authors       = ["Dave Copeland"]
  spec.email         = ["davec@naildrivin5.com"]
  spec.summary       = %q{A minimal library for managing a service layer in Rails by allowing services to declare their dependencies upon each other}
  spec.homepage      = "https://github.com/sustainable-rails/active_service"
  spec.license       = "Hippocratic"

  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/sustainable-rails/active_service"
  spec.metadata["changelog_uri"] = "https://github.com/sustainable-rails/active_service/releases"

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency("activesupport")
  spec.add_development_dependency("rspec")
  spec.add_development_dependency("rspec_junit_formatter")
  spec.add_development_dependency("confidence-check")
end
