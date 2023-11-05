# frozen_string_literal: true

require_relative 'extensions/last_error'
require_relative 'extensions/shard'

# Arj extensions:
# - {Arj::Extensions::Shard}     - Adds a +shard+ attribute to a job class.
# - {Arj::Extensions::LastError} - Adds a +last_error+ attribute to a job class.
module Extensions; end
