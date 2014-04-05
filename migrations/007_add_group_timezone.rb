Sequel.migration do
  change do
    add_column :groups, :timezone, String
  end
end