Sequel.migration do
  change do
    rename_column :callbacks, :last_callback_received_date, :last_response_received_date
    rename_column :callbacks, :last_callback_sent_date, :last_payload_sent_date
  end
end