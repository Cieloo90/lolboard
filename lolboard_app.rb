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

br.goto(link)
discussion_table = br.div(class: %w[discussions main]).html
n_discussion_table = Nokogiri::HTML.parse(discussion_table)

### to do \/ pagination on discussion table site \/ ###

n_discussion_table.css('.discussion-list-item').each_with_index do |row, index|
  topics[index] = {
    href: row['data-href'],
    unique_code: row['data-discussion-id'],
    comms: row['data-comments']
  }
end

conn_sq = Sequel.postgres(
  'lolboard_db_tests',
  user: 'postgres',
  password: 'password',
  host: '172.17.0.2',
  port: '5432'
)

topics.each_with_index do |single_topic, index|
  unique_code_checker = conn_sq[:topics].where(unique_code: single_topic[:unique_code])

  if unique_code_checker.count.zero? && index < 10
    br.goto("https://boards.eune.leagueoflegends.com/#{single_topic[:href]}?show=flat")
    add_topic(br, conn_sq, single_topic[:unique_code])
    puts "record with hash - #{single_topic[:unique_code]} added to database"

  elsif unique_code_checker.count > 0
    if conn_sq[:topics].where(unique_code: single_topic[:unique_code]).get(:comm_amount) != single_topic[:comms].to_i
      puts 'amount of comments changed, need update'
      br.goto("https://boards.eune.leagueoflegends.com/#{single_topic[:href]}?show=flat")
      check_comments(br, conn_sq, single_topic[:unique_code])
    else
      puts 'up to date'
    end
  else
    print '. ' ### every forbidden
  end
end
