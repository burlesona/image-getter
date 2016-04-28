ENV['APP_ENV'] = 'test'
require_relative '../environment'
require 'db/connect'
require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/hell'
require 'minitest/reporters'
Minitest::Reporters.use!
class Minitest::Test
  parallelize_me!
end

# Define behavior for all describe blocks
# This ensures all tests are run inside a database
# transaction so they can't throw off any fixtures.
class ImageGetterSpec < MiniTest::Spec
  def run(*args, &block)
    result = nil
    Sequel::Model.db.transaction(:rollback=>:always, :auto_savepoint=>true){result = super}
    result
  end
end
MiniTest::Spec.register_spec_type /.*/, ImageGetterSpec

# So that I don't have to type the namespace a million times in tests
include ImageGetter

# So that router tests work
def app
  ImageGetter::Router
end
