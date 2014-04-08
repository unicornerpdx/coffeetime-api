Sequel.migration do
  change do
    rename_column :groups, :github_group_id, :github_team_id
  end
end