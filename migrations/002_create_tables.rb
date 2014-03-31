Sequel.migration do
  up do
    create_table(:groups) do
      primary_key :id
      String :github_group_id
      String :name
    end
    create_table(:callbacks) do
      primary_key :id
      foreign_key :group_id, :groups
      String :url
      DateTime :last_callback_sent_date
      String :last_payload_sent
      String :last_response_received
      Integer :last_response_code
    end
    create_table(:devices) do
      primary_key :id
      foreign_key :user_id, :users
      String :uuid
      String :apns_production_token
      String :apns_sandbox_token
      String :gcm_token
      Boolean :active
    end
    create_table(:memberships) do
      foreign_key :group_id, :groups
      foreign_key :user_id, :users
      Integer :balance
      Boolean :active
    end
    create_table(:transactions) do
      primary_key :id
      DateTime :date
      foreign_key :group_id, :groups
      foreign_key :from_user_id, :users
      foreign_key :to_user_id, :users
      Integer :amount
      foreign_key :created_by, :users
      String :note
      column :location, :geography
      Float :accuracy
      DateTime :location_date
    end
  end

  down do
    drop_table(:groups)
    drop_table(:callbacks)
    drop_table(:devices)
    drop_table(:memberships)
    drop_table(:transactions)
  end
end