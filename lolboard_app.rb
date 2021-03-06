require 'watir'
require 'nokogiri'
require 'sequel'
require 'pry'

require './functions/check_comments.rb'
require './functions/add_topic.rb'

br = Watir::Browser.new :chrome
br.window.resize_to(1920, 1080)
br.window.move_to(0, 0)
link = 'https://boards.eune.leagueoflegends.com/en/'
topics_href   = []
topics_hash   = []
topics_comms  = []

br.goto(link)
discussion_table = br.div(class: %w[discussions main]).html
n_discussion_table = Nokogiri::HTML.parse(discussion_table)

### to do \/ pagination on discussion table site \/ ###

n_discussion_table.css('.discussion-list-item').each do |row|
  topics_href.push(row['data-href'])
  topics_hash.push(row['data-discussion-id'])
  topics_comms.push(row['data-comments'])
end

conn_sq = Sequel.postgres(
  'lolboard_db_tests',
  user: 'postgres',
  password: 'password',
  host: '172.17.0.2',
  port: '5432'
)

topics_hash.each_with_index do |hash, index|
  hash_check = conn_sq[:topics].where(unique_code: hash)

  if hash_check.count.zero? && index < 10
    br.goto('https://boards.eune.leagueoflegends.com/' + topics_href[index] + '?show=flat')
    add_topic(br, conn_sq, hash)
    puts "record with hash - #{hash} added to database"

  elsif hash_check.count > 0
    if conn_sq[:topics].where(unique_code: hash).get(:comm_amount) != topics_comms[index].to_i
      puts 'amount of comments changed, need update'
      br.goto('https://boards.eune.leagueoflegends.com/' + topics_href[index] + '?show=flat')
      check_comments(br, conn_sq, hash)
    else
      puts 'up to date'
    end
  else
    print '. ' ### every forbidden
  end
end
