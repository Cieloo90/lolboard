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
      comm_inner_id = comm['id']
      comm_date = Time.parse(comm.css('.timeago > span')[0]['title'])

      comm_exist = Comments[inner_id: comm_inner_id, date: comm_date]

      if comm_exist
        prev_comm_id = comm_exist[:id]

      else
        new_comm = Comments.create(
          topic_id: prev_comm_id ? nil : this_topic[:id],
          prev_comm_id: prev_comm_id || nil,
          inner_id: comm_inner_id,
          author: 'comm_author',
          date: comm_date,
          content: 'comm_content'
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

  # topic_title = n_topic.css('.discussion-title > h1 > span')[1].text
  topic_author = n_topic.css('.username').text
  topic_date = Time.parse(n_topic.css('.author-info > span')[0]['title'])
  # topic_content = n_topic.css('#content').text

  Topics.create(
    comm_amount: 0,
    title: 'topic_title',
    unique_code: unique,
    author: topic_author,
    date: topic_date,
    content: 'topic_content'
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

def check_for_topics(browser, topics)
  Topics.each do |tpc_from_db|
    is_topic_on_site = false
    topics.each do |tpc_from_site|
      is_topic_on_site = true if tpc_from_db[:unique_code] == tpc_from_site[:unique_code]
    end
    next unless is_topic_on_site == false

    sleep(0.5)
    browser.link(class: 'show-more').click
    topics = parse_discussion_table(browser)
    check_for_topics(browser, topics)
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

br.goto('https://boards.eune.leagueoflegends.com/en/')

topics = parse_discussion_table(br)
check_for_topics(br, topics)

topics.each_with_index do |topic, index|
  topic_in_db = Topics[unique_code: topic[:unique_code]]

  if !topic_in_db && index < 10
    br.goto("https://boards.eune.leagueoflegends.com/#{topic[:href]}?show=flat")
    add_topic(br, topic[:unique_code])
  elsif topic_in_db
    if topic_in_db[:comm_amount] != topic[:comms].to_i
      br.goto("https://boards.eune.leagueoflegends.com/#{topic[:href]}?show=flat")
      check_comments(br, topic[:unique_code])
    end
  end
end
