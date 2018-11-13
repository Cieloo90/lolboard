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
topics = []

conn_sq = Sequel.postgres(
  'lolboard_db_tests',
  user: 'postgres',
  password: 'password',
  host: '172.17.0.2',
  port: '5432'
)

class Comments < Sequel::Model
end

class Topics < Sequel::Model
end

br.goto(link)
n_discussion_table = Nokogiri::HTML.parse(br.div(class: %w[discussions main]).html)

### to do \/ pagination on discussion table site \/ ###

topics = n_discussion_table.css('.discussion-list-item').map do |row|
  {
    href: row['data-href'],
    unique_code: row['data-discussion-id'],
    comms: row['data-comments']
  }
end

topics.each_with_index do |topic, index|
  unique_code_checker = Topics[unique_code: topic[:unique_code]]

  if !unique_code_checker && index < 10
    br.goto("https://boards.eune.leagueoflegends.com/#{topic[:href]}?show=flat")
    add_topic(br, topic[:unique_code])
    puts "record with unique_code - #{topic[:unique_code]} added to database"

  elsif unique_code_checker
    if unique_code_checker[:comm_amount] != topic[:comms].to_i
      puts 'amount of comments changed, need update'
      br.goto("https://boards.eune.leagueoflegends.com/#{topic[:href]}?show=flat")
      check_comments(br, topic[:unique_code])
    else
      puts 'up to date'
    end
  else
    print '. ' ### every forbidden
  end
end
