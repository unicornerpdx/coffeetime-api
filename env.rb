ENV['TZ'] = 'UTC'

unless File.exists? './config.yml'
  puts 'Please provide a config.yml file.'
  exit false
end

require 'yaml'
require 'securerandom'

if ENV['RACK_ENV']
  SiteConfig = YAML.load_file('config.yml')[ENV['RACK_ENV']]
else
  SiteConfig = YAML.load_file('config.yml')['development']
end

db = SiteConfig['db']
SQL = Sequel.postgres(db['name'], :user => db['user'], :password => db['pass'], :host => db['host'], :port => db['port'])
SQL.loggers << Logger.new($stdout)

