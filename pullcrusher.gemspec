# -*- encoding: utf-8 -*-
require File.expand_path('../lib/pullcrusher/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Matthew Rothenberg"]
  gem.email         = ["mrothenberg@gmail.com"]
  gem.description   = %q{Optimize all images in a GitHub repository, then easily send a pull request with the changes.}
  gem.summary       = %q{Optimize all images in a GitHub repository, then easily send a pull request with the changes.}
  gem.homepage      = "http://github.com/mroth/pullcrusher"

  gem.add_development_dependency 'rdoc',    '~> 4.1.1'
  gem.add_development_dependency 'aruba',   '~> 0.6.1'
  gem.add_development_dependency 'rake',    '~> 10.3'
  gem.add_development_dependency 'rspec',   '~> 2.99'

  gem.add_runtime_dependency 'methadone',   '~> 1.7.0'
  gem.add_runtime_dependency 'git',         '~> 1.2.8'
  gem.add_runtime_dependency 'octokit',     '~> 3.3.1' #1.3.0 added authorizations, 2.x adds breaking changes
  gem.add_runtime_dependency 'virtus',      '~> 0.5.4' #1.0x breaks 1.8.7/1.9.2 compatibility
  gem.add_runtime_dependency 'image_optim', '~> 0.15'
  gem.add_runtime_dependency 'highline',    '~> 1.6.21'

  # gem.add_runtime_dependency "multipart-post", "~>1.2.0" #force version to avoid 1.9.3 install error?

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "pullcrusher"
  gem.require_paths = ["lib"]
  gem.version       = Pullcrusher::VERSION
end
