Sequel.migration do
  up do
    drop_column :devices, :apns_production_token
    drop_column :devices, :apns_sandbox_token
    drop_column :devices, :gcm_token
    add_column :devices, :token, String
    add_column :devices, :token_type, String
  end
  down do
    drop_column :devices, :token
    drop_column :devices, :token_type
    add_column :devices, :apns_production_token, String
    add_column :devices, :apns_sandbox_token, String
    add_column :devices, :gcm_token, String
  end
end