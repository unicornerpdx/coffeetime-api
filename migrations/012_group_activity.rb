Sequel.migration do
  change do
    add_column :groups, :last_active_date, DateTime
    add_column :groups, :last_active_github_token, String
  end
end