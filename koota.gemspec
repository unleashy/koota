# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'koota/version'

Gem::Specification.new do |spec|
  spec.name          = 'koota'
  spec.version       = Koota::VERSION
  spec.authors       = ['unleashy']
  spec.email         = ['unleashy@users.noreply.github.com']

  spec.summary       = 'Koota generates words given a pattern.'
  spec.homepage      = 'https://github.com/unleashy/koota'
  spec.license       = 'MIT'

  spec.metadata['homepage_uri']    = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/unleashy/koota'
  spec.metadata['changelog_uri']   = 'https://github.com/unleashy/koota/blob/master/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'slop', '~> 4.7'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '>= 0.75'
  spec.add_development_dependency 'simplecov', '~> 0.17'
end
