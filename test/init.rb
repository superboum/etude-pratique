require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

#Unit tests
require_relative 'unit/article'
require_relative 'unit/page'
require_relative 'unit/user'

#Functionnal tests
# require_relative 'functionnal/article'
require_relative 'functionnal/event'
