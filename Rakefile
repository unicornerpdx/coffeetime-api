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

    active_groups = SQL[:groups].where{last_active_date > Date.today - 1}.exclude(:last_active_github_token => '')
    active_groups.each do |group|
      github = Octokit::Client.new :access_token => group[:last_active_github_token]
      result = GroupHelper.update_group_members_from_github github, group

      active_users = SQL[:users].select(Sequel.lit('users.*')).join(:memberships, :user_id => :id).where(:memberships__group_id => group[:id], :active => true)

      active_users.each do |user|

        added = result[:added].map{|u| u[:display_name] == user[:display_name] ? 'you' : u[:display_name]}
        removed = result[:removed].map{|u| u[:display_name] == user[:display_name] ? 'you' : u[:display_name]}
        
        msg = nil
        if added.length == 1
          msg = "#{added.first} #{added.first == 'you' ? 'were' : 'was'} added to the group \"#{group[:name]}\""
        elsif added.length > 1
          msg = "#{added[0...-1].join(', ')} and #{added.last} were added to the group \"#{group[:name]}\""
        end

        if msg
          msg.gsub!(/^you/, 'You') # Capitalize if the sentence starts with "you", otherwise it's a nickname so don't change the capitalization
          puts "Sending to #{user[:username]}: #{msg}"
          Pushie.send(user, msg, {:group_id => group[:id]})
        end

        msg = nil
        if removed.length == 1
          msg = "#{removed.first} #{removed.first == 'you' ? 'were' : 'was'} removed from the group \"#{group[:name]}\""
        elsif removed.length > 1
          msg = "#{removed[0...-1].join(', ')} and #{removed.last} were removed from the group \"#{group[:name]}\""
        end

        if msg
          msg.gsub!(/^you/, 'You') # Capitalize if the sentence starts with "you", otherwise it's a nickname so don't change the capitalization
          puts "Sending to #{user[:username]}: #{msg}"
          Pushie.send(user, msg, {:group_id => group[:id]})
        end

      end

      SQL[:groups].where(:id => group[:id]).update(:last_active_github_token => '')
    end
  end

end

