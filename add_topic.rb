require 'watir'
require 'nokogiri'
require 'pry'
require 'sequel'

## vars ##

br = Watir::Browser.new :chrome
link = 'https://boards.eune.leagueoflegends.com/en/'

##

br.goto(link)
discussion_table = br.div(class: %w[discussions main]).html
n_discussion_table = Nokogiri::HTML.parse(discussion_table)

n_discussion_table_rows_arr = []
n_discussion_table.css('.discussion-list-item').map do |row|
  n_discussion_table_rows_arr.push(row['data-href'])
end

conn_sq = Sequel.postgres(
  'lolboard_db_tests',
  user: 'postgres',
  password: 'password',
  host: '172.17.0.2',
  port: '5432'
)

def single_topic(browser, topic_href, db_conn)
  browser.goto('https://boards.eune.leagueoflegends.com/' + topic_href)
  topic = browser.div(class: 'op-container').html
  n_topic = Nokogiri::HTML.parse(topic)

  topic_title = n_topic.css('.discussion-title > h1 > span')[1].text
  topic_author = n_topic.css('.username').text
  topic_content = n_topic.css('#content').text

  db_conn[:topics].insert(
    first_comm: 0,
    topicTitle: topic_title,
    topicAuthor: topic_author,
    topicContent: topic_content[21..50] + '...'
  )
end

single_topic(br, n_discussion_table_rows_arr[5], conn_sq)

i = 0
while i < 9
  single_topic(br, n_discussion_table_rows_arr[i], conn_sq)
  i += 1
end
