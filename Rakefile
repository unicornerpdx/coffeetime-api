Encoding.default_internal = 'UTF-8'
require 'rubygems'
require 'rake/testtask'
Bundler.require

require './env.rb'

Dir.glob(['lib'].map! {|d| File.join d, '*.rb'}).each do |f| 
  require_relative f
end

Rake::TestTask.new do |t|
  t.test_files = FileList['test/coffee/*_test.rb']
  t.verbose = true
end

namespace :debug do
  task :push, [:username] do |t, args|
    Pushie.send SQL[:users].first(:username=>args[:username]), 'test pushie!', {badge: 2, group_id:11, transaction_id: 300}
  end
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

namespace :group do

  task :update_active do 
    puts "Updating members for all recently active groups"

    pushie = Pushie.new 

    active_groups = SQL[:groups].where{last_active_date > Date.today - 1}.exclude(:last_active_github_token => '')
    active_groups.each do |group|
      github = Octokit::Client.new :access_token => group[:last_active_github_token]
      result = GroupHelper.update_group_members_from_github github, group
      GroupHelper.send_notifications_about_changed_members group, result, pushie

      SQL[:groups].where(:id => group[:id]).update(:last_active_github_token => '')
    end
  end

end

