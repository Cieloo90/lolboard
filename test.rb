require 'watir'
require 'nokogiri'
require 'pry'
require 'pg'

## vars ##

$br = Watir::Browser.new :chrome
link = 'https://boards.eune.leagueoflegends.com/en/'

##

$br.goto(link)
discussion_table = $br.div(class: %w[discussions main]).html
n_discussion_table = Nokogiri::HTML.parse(discussion_table)

n_discussion_table_rows_arr = []
n_discussion_table.css('.discussion-list-item').map do |row|
  n_discussion_table_rows_arr.push(row['data-href'])
end

def single_topic(topic_href, file_index)
  $br.goto('https://boards.eune.leagueoflegends.com/' + topic_href)
  topic = $br.div(class: 'op-container').html
  n_topic = Nokogiri::HTML.parse(topic)

  topic_title = n_topic.css('.discussion-title > h1 > span')[1].text
  topic_author = n_topic.css('.username').text
  topic_content = n_topic.css('#content').text

  File.open('Topic_' + file_index.to_s + '.txt', 'w') do |f|
    f.write(
      'Title: ', topic_title,	"\n",
      'Author: ', topic_author,	"\n",
      'Content: ', "\n", topic_content,	"\n"
    )
  end
end

i = 0

while i < 10
  single_topic(n_discussion_table_rows_arr[i], i + 1)
  i += 1
end
