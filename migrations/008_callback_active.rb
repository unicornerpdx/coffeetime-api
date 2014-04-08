Sequel.migration do
  change do
    add_column :callbacks, :active, :boolean
  end
end