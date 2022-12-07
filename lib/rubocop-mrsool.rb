# frozen_string_literal: true

require 'rubocop'

require_relative 'rubocop/mrsool'
require_relative 'rubocop/mrsool/version'
require_relative 'rubocop/mrsool/inject'

RuboCop::Mrsool::Inject.defaults!

require_relative 'rubocop/cop/mrsool_cops'
