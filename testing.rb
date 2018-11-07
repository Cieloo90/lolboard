require 'watir'
require 'nokogiri'
require 'sequel'
require 'pry'

br = Watir::Browser.new :chrome
link = 'https://boards.eune.leagueoflegends.com/en/c/off-topic-en/REuykUtn-4-rp'

br.goto(link)
comments = br.div(class: 'list').html
n_comments = Nokogiri::HTML.parse(comments)

n_comments.css('.nested-comment').each_with_index do |comm, _index|
  puts comm.css('.timeago > span')[0]['title'][0..15].tr('T', ' ')
end
