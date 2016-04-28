ROOT_DIR = Dir.pwd
$: << ROOT_DIR

require 'dotenv'
Dotenv.load

module ImageGetter
  ValidationError = Class.new(StandardError)
end
