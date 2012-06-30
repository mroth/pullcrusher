# -*- encoding: utf-8 -*-
require File.expand_path('../lib/pullcrusher/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Matthew Rothenberg"]
  gem.email         = ["mrothenberg@gmail.com"]
  gem.description   = %q{Optimize all images in a GitHub repository, then easily send a pull request with the changes.}
  gem.summary       = %q{Optimize all images in a GitHub repository, then easily send a pull request with the changes.}
  gem.homepage      = "http://github.com/mroth/pullcrusher"

  gem.add_development_dependency('rdoc')
  gem.add_development_dependency('aruba')
  gem.add_development_dependency('rake','~> 0.9.2')
  gem.add_dependency('methadone', '~>1.2.1')

  gem.add_runtime_dependency "git"
  gem.add_runtime_dependency "octokit", ">= 1.3.0" #1.3.0 added authorizations
  gem.add_runtime_dependency "virtus"
  gem.add_runtime_dependency "image_optim"
  gem.add_runtime_dependency "highline"
  gem.add_runtime_dependency "json" #needed for ruby 1.8 #TODO: figure out how to scope to platform?

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "pullcrusher"
  gem.require_paths = ["lib"]
  gem.version       = Pullcrusher::VERSION
end
