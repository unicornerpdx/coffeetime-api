Encoding.default_internal = 'UTF-8'
require 'rubygems'
require 'rake/testtask'
Bundler.require

require './env.rb'

Rake::TestTask.new do |t|
  t.test_files = FileList['test/coffee/*_test.rb']
  t.verbose = true
end

namespace :db do

  task :migrate, [:version] do |t, args|
    Sequel.extension :migration
    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run(SQL, "migrations", target: args[:version].to_i)
    else
      puts "Migrating to latest"
      Sequel::Migrator.run(SQL, "migrations")
    end
  end

end
