# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rovfer/version'

Gem::Specification.new do |spec|
  spec.name          = "rovfer"
  spec.version       = Rovfer::VERSION
  spec.authors       = ["Chris Thompson"]
  spec.email         = ["chris.thompson@govdelivery.com"]
  spec.summary       = %q{Manipulate Open Virtualization Format (OVF) xml files}
  spec.description   = %q{Manipulate Open Virtualization Format (OVF) xml files}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri", "~> 1.6"
  spec.add_dependency "thor", "~> 0.19.1"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "bundler_geminabox"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "byebug", "~> 3.2"
end
