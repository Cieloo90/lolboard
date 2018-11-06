require 'pg'
require 'sequel'

begin
  conn_pg = PG.connect(
    '172.17.0.2',
    '5432',
    '',
    '',
    'test',
    'postgres',
    'password'
  )

  res = conn_pg.exec('select * from test_t')
  puts res[0]['testid']
rescue StandardError
  puts 'no connection SQ'
end

begin
  conn_sq = Sequel.postgres(
    'test',
    user: 'postgres',
    password: 'password',
    host: '172.17.0.2',
    port: '5432'
  )

  test = conn_sq[:test_t]
  puts test.all(:testid)
rescue StandardError
  puts 'no connection SQ'
end
