Sequel.migration do
  change do
    add_column :callbacks, :last_response_status, String
  end
end