require 'rake/testtask'
require_relative 'environment'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
end

Dir['./tasks/**/*.rake'].each do |file|
  load file
end
