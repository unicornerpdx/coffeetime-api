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
        removed << SQL[:users].first(:id => member[:user_id])
      end
    end

    {
      added: added,
      removed: removed
    }
  end

end