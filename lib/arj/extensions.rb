# frozen_string_literal: true

require_relative 'extensions/last_error'
require_relative 'extensions/shard'
require_relative 'extensions/timeout'

module Arj
  # Arj extensions:
  # - {Arj::Extensions::Shard}     - Adds a +shard+ attribute to a job class.
  # - {Arj::Extensions::LastError} - Adds a +last_error+ attribute to a job class.
  # - {Arj::Extensions::Timeout}   - Adds job timeouts.
  module Extensions; end
end
