Sequel.migration do
  up do
    create_table(:users) do
      primary_key :id
      String :github_user_id
      String :username
      String :display_name
      String :avatar_url
    end
  end

  down do
    drop_table(:users)
  end
end