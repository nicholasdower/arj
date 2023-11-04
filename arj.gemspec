# frozen_string_literal: true

require_relative 'lib/arj/version'

Gem::Specification.new do |spec|
  spec.name          = 'arj'
  spec.description   = 'Active Record Job'
  spec.summary       = 'An ActiveJob queuing backend which uses ActiveRecord.'
  spec.homepage      = 'https://github.com/nicholasdower/arj'
  spec.version       = Arj::VERSION
  spec.license       = 'MIT'
  spec.authors       = ['Nick Dower']
  spec.email         = 'nicholasdower@gmail.com'

  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.required_ruby_version = '>= 3.2.2'

  spec.files = Dir['lib/**/*']

  spec.add_dependency 'activejob', '~>  7.0'
  spec.add_dependency 'activerecord', '~>  7.0'
end
