# frozen_string_literal: true

module Arj
  VERSION = File.read(File.expand_path(File.join(__dir__, '..', '..', '.release-version'))).strip
end
