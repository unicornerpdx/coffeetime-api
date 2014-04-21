class GroupHelper

  def self.get_membership(group_id, user_id) 
    SQL[:memberships].where(:group_id => group_id, :user_id => user_id)
  end

  def self.add_user_to_group_from_github(member, group)
    user = SQL[:users].first :github_user_id => member.id.to_s
    if !user
      # Create user records for any users not already in the database
      SQL[:users] << {
        github_user_id: member.id.to_s,
        username: member.login,
        display_name: member.login,
        avatar_url: member.rels[:avatar].href,
        date_updated: DateTime.now,
        date_created: DateTime.now
      }
      user = SQL[:users].first :github_user_id => member.id.to_s
      LOG.debug "create_user from_github", nil, user, group
    end
    # Add the member to the group if they are not already
    membership = self.get_membership(group[:id], user[:id]).first
    if !membership
      SQL[:memberships] << {
        group_id: group[:id],
        user_id: user[:id],
        balance: 0,
        active: true,
        date_updated: DateTime.now,
        date_created: DateTime.now
      }
      LOG.debug "add_membership", nil, user, group
      return user # Return the user if they were added 
    else
      # Re-activate the user if there was already a membership for them
      if membership[:active] == false
        self.get_membership(group[:id], user[:id]).update(:active => true)
        return user # Return the user if they were added 
      end
    end
  end

  def self.update_group_members_from_github(github, group)

    # Add any new people from the Github team
    added = []
    github_member_ids = []
    members = github.team_members group[:github_team_id]
    members.each do |member|
      github_member_ids << member.id.to_s
      result = self.add_user_to_group_from_github(member, group)
      added << result if result
    end

    # Check existing member list and deactivate them if they are not in the Github team anymore
    removed = []
    members = SQL[:memberships].select(:memberships__id, :memberships__user_id, :users__github_user_id).join(:users, :id => :user_id).where(:group_id => group[:id], :active => true)
    members.each do |member|
      if !github_member_ids.include? member[:github_user_id]
        SQL[:memberships].where(:id => member[:id]).update(:active => false)
        LOG.debug "remove_membership", nil, user, group
        removed << SQL[:users].first(:id => member[:user_id])
      end
    end

    {
      added: added,
      removed: removed
    }
  end

  def self.send_notifications_about_changed_members(group, result, pushie)
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
        pushie.push(user, msg, {:group_id => group[:id]})
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
        pushie.push(user, msg, {:group_id => group[:id]})
      end

    end
  end

end

class GroupUpdater
  include Celluloid::IO

  def update_user_groups(user, github_access_token, pushie)
    Octokit.auto_paginate = true
    octokit = Octokit::Client.new :access_token => github_access_token
    teams = octokit.user_teams 

    teams.each do |team|
      group = SQL[:groups].first(:github_team_id => team['id'].to_s)
      if group
        puts "Updating members for group #{group[:id]} #{group[:name]}"
        result = GroupHelper.update_group_members_from_github octokit, group
        GroupHelper.send_notifications_about_changed_members group, result, pushie
      end
    end
  end

end
