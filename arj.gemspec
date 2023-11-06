# frozen_string_literal: true

require_relative 'lib/arj/version'

Gem::Specification.new do |spec|
  spec.name          = 'arj'
  spec.description   = 'Active Record Job'
  spec.license       = 'MIT'
  spec.summary       = 'An ActiveJob queuing backend which uses ActiveRecord.'
  spec.homepage      = 'https://github.com/nicholasdower/arj'
  spec.version       = Arj::VERSION
  spec.license       = 'MIT'
  spec.authors       = ['Nick Dower']
  spec.email         = 'nicholasdower@gmail.com'

  spec.metadata      = {
    'bug_tracker_uri'       => 'https://github.com/nicholasdower/arj/issues',
    'changelog_uri'         => "https://github.com/nicholasdower/arj/releases/tag/v#{Arj::VERSION}",
    'documentation_uri'     => "https://www.rubydoc.info/github/nicholasdower/arj/v#{Arj::VERSION}",
    'homepage_uri'          => 'https://github.com/nicholasdower/arj',
    'rubygems_mfa_required' => 'true',
    'source_code_uri'       => 'https://github.com/nicholasdower/arj'
  }
  spec.required_ruby_version = '>= 3.2.2'

  spec.files = Dir['lib/**/*']

  spec.add_runtime_dependency 'activejob', '~>  7.1'
  spec.add_runtime_dependency 'activerecord', '~>  7.1'
end
