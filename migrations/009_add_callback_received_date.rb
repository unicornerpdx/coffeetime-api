Sequel.migration do
  change do
    add_column :callbacks, :last_callback_received_date, DateTime
  end
end