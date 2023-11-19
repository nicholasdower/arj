# frozen_string_literal: true

require_relative 'extensions/id'
require_relative 'extensions/last_error'
require_relative 'extensions/persistence'
require_relative 'extensions/query'
require_relative 'extensions/retain_discarded'
require_relative 'extensions/shard'
require_relative 'extensions/timeout'

module Arj
  # Arj extensions:
  # - {Arj::Extensions::LastError} - Adds a +last_error+ attribute to a job class.
  # - {Arj::Extensions::Persistence}   - Adds job timeouts.
  # - {Arj::Extensions::Query}   - Adds job timeouts.
  # - {Arj::Extensions::RetainDiscarded}   - Adds job timeouts.
  # - {Arj::Extensions::Shard}     - Adds a +shard+ attribute to a job class.
  # - {Arj::Extensions::Timeout}   - Adds job timeouts.
  module Extensions; end
end
