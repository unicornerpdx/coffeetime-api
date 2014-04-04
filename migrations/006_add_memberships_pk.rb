Sequel.migration do
  change do
    alter_table(:memberships) {
      add_primary_key :id
    }
  end
end