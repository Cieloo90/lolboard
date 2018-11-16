require 'watir'
require 'nokogiri'
require 'sequel'
require 'pry'

def check_comments(browser, unique)
  this_topic = Topics[unique_code: unique]
  w_comments = ''
  prev_comm_id = nil

  if browser.div(class: 'flat-comments').exists?
    browser.div(class: 'pager').links.each do |pager_link|
      if pager_link.text
        pager_link.click
        w_comments += browser.div(class: 'flat-comments').html
      end
    end
    n_comments = Nokogiri::HTML.parse(w_comments).css('.nested-comment')

    n_comments.each do |comm|
      inner_id = comm['id']
      date = Time.parse(comm.css('.timeago > span')[0]['title'])

      last_comm = Comments[inner_id: inner_id, date: date]

      if last_comm
        prev_comm_id = last_comm[:id]

      else
        new_comm = Comments.create(
          topic_id: prev_comm_id ? nil : this_topic[:id],
          prev_comm_id: prev_comm_id || nil,
          inner_id: inner_id,
          author: 'author',
          date: date,
          content: 'content'
        )

        unless prev_comm_id
          Topics[id: this_topic[:id]].update(first_comm: new_comm[:id])
        end
        prev_comm_id = new_comm[:id]
      end
    end
  end
  Topics[id: this_topic[:id]].update(comm_amount: n_comments.count)
end

def add_topic(browser, unique)
  w_topic = browser.div(class: 'op-container').html
  n_topic = Nokogiri::HTML.parse(w_topic)

  # title = n_topic.css('.discussion-title > h1 > span')[1].text
  author = n_topic.css('.username').text
  date = if browser.div(class: 'author-info').span(class: 'tags').exists?
           Time.parse(n_topic.css('.author-info > span')[1]['title'])
         else
           Time.parse(n_topic.css('.author-info > span')[0]['title'])
         end
  # content = n_topic.css('#content').text

  Topics.create(
    comm_amount: 0,
    title: 'title',
    unique_code: unique,
    author: author,
    date: date,
    content: 'content'
  )

  check_comments(browser, unique)
end

def parse_discussion_table(browser)
  n_discussion_table = Nokogiri::HTML.parse(browser.div(class: %w[discussions main]).html)

  topics = n_discussion_table.css('.discussion-list-item').map do |row|
    {
      href: row['data-href'],
      unique_code: row['data-discussion-id'],
      comms: row['data-comments']
    }
  end
  topics
end

require './functions/check_for_topics.rb'

def remain_db_topics(site_tpcs)
  db_tpcs = []
  Topics.each do |tpc|
    db_tpcs.push(tpc) if tpc[:present] == true
  end
  site_tpcs.each do |site_tpc|
    if db_tpcs.include?(Topics[unique_code: site_tpc[:unique_code]])
      db_tpcs.delete(Topics[unique_code: site_tpc[:unique_code]])
    end
  end
  db_tpcs
end

def next_topic_page(browser)
  if browser.link(class: 'show-more').present?
    browser.link(class: 'show-more').click
    sleep(0.5)
    true
  else
    false
  end
end

br = Watir::Browser.new :chrome
br.window.resize_to(1920, 1080)
br.window.move_to(0, 0)

Sequel.postgres(
  'lolboard_db_tests',
  user: 'postgres',
  password: 'password',
  host: '172.17.0.2',
  port: '5432'
)

class Comments < Sequel::Model
  def next_comm
    Comments[prev_comm_id: self[:id]]
  end
end

class Topics < Sequel::Model
end

### INFINITE LOOP ###

br.goto('https://boards.eune.leagueoflegends.com/en/')

site_topics = parse_discussion_table(br)

while remain_db_topics(site_topics).count > 0 && next_topic_page(br)
  next_topic_page(br)
  site_topics = parse_discussion_table(br)
end

remain_db_topics(site_topics).each do |r_tpc|
  puts "topic #{r_tpc[:unique_code]} not found"
  Topics[unique_code: r_tpc[:unique_code]].update(present: false)
end

site_topics.each_with_index do |topic, index|
  topic_in_db = Topics[unique_code: topic[:unique_code]]

  if !topic_in_db && index < 10
    br.goto("https://boards.eune.leagueoflegends.com/#{topic[:href]}?show=flat")
    add_topic(br, topic[:unique_code])
  elsif topic_in_db
    if topic_in_db[:comm_amount] != topic[:comms].to_i
      br.goto("https://boards.eune.leagueoflegends.com/#{topic[:href]}?show=flat")
      check_comments(br, topic[:unique_code])
    else
      puts "topic #{index} up to date"
    end
  end
end
### INFINITE LOOP END ###
