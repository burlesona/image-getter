require 'sequel'

if ENV['APP_ENV'] == 'test'
  puts "Connecting to TEST database"
  DB = Sequel.connect(ENV['TEST_DATABASE_URL'])
else
  puts "Connecting to database"
  DB = Sequel.connect(ENV['DATABASE_URL'], :max_connections => 16)
end

# Dabase Extensions
DB.extension :pg_array

# Plugins and config
Sequel::Model.plugin :timestamps
Sequel.extension :pg_array_ops
