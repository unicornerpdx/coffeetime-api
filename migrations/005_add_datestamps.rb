Sequel.migration do
  change do
    [:callbacks, :devices, :groups, :memberships, :transactions, :users].each {|table| 
      add_column table, :date_created, DateTime
      add_column table, :date_updated, DateTime
    }
  end
end