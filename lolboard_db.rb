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

conn_sq.create_table!(:topics) do
  primary_key :topicId, serial: true
  Integer :topicCommAmount, null: true
  Integer :topicFirstComm, null: true
  String :topicTitle, null: false
  String :topicAuthor, null: false
  DateTime :topicDate, null: true
  String :topicContent, null: false
end

conn_sq.create_table!(:comments) do
  primary_key :commId, serial: true
  Integer :commTopicId, null: true
  Integer :commPrevComm, null: true
  Integer :commNestedComm, null: true
  String :commAuthor, null: false
  DateTime :commDate, null: true
  String :commContent, null: false
end
