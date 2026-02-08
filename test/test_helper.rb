# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "fred"

require "sus"
require "json"
require "securerandom"

TEST_API_KEY = SecureRandom.hex(16)
