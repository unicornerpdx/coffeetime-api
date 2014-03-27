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
  task :setup do
    SQL.create_table :stats do
      primary_key [:group_id, :client_id, :date, :key, :value]
      String :group_id
      String :client_id
      DateTime :date
      String :key
      String :value
      Integer :num
      index [:group_id, :client_id, :date, :key]
      index [:client_id, :date, :key]
      index [:date, :key]
      index [:key]
    end
  end
end
