require 'sequel'

begin
  conn_sq = Sequel.postgres(
    'lolboard_db_tests',
    user: 'postgres',
    password: 'password',
    host: '172.17.0.2',
    port: '5432'
  )
rescue Extenction
  abort('Connection failed')
end

conn_sq.create_table?(:topics) do
  primary_key :id, serial: true
  String      :unique_code, null: false
  Integer     :comm_amount, null: true
  Integer     :first_comm, null: true
  String      :title, null: false
  String      :author, null: false
  DateTime    :date, null: true
  String      :content, null: false
  TrueClass   :present, null: false, default: true
end

# conn_sq.alter_table(:topics) do
#   add_column :present, TrueClass, default: true
# end

conn_sq.create_table?(:comments) do
  primary_key :id, serial: true
  Integer     :topic_id, null: true
  Integer     :prev_comm_id, null: true
  String      :inner_id, null: true
  String      :author, null: true
  DateTime    :date, null: true
  String      :content, null: true
end
