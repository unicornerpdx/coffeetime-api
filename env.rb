unless File.exists? './config.yml'
  puts 'Please provide a config.yml file.'
  exit false
end

require 'yaml'

if ENV['RACK_ENV']
  SiteConfig = YAML.load_file('config.yml')[ENV['RACK_ENV']]
else
  SiteConfig = YAML.load_file('config.yml')['development']
end

db_url = "postgres://%s@%s:%d/%s" % [
    SiteConfig['db']['user'], SiteConfig['db']['host'], SiteConfig['db']['port'], SiteConfig['db']['name']
]
SQL = Sequel.connect(db_url)
SQL.loggers << Logger.new($stdout)

