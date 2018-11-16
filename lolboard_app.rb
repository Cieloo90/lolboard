require 'watir'
require 'nokogiri'
require 'sequel'
require 'pry'

br = Watir::Browser.new :chrome, headless: true
# br.window.resize_to(1920, 1080)
# br.window.move_to(0, 0)

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

def parse_discussion_table(browser, page)
  start_index = page * 50
  n_discussion_table = Nokogiri::HTML.parse(browser.div(class: %w[discussions main]).html)
  topics = n_discussion_table.css('.discussion-list-item').map do |row|
    {
      href: row['data-href'],
      unique_code: row['data-discussion-id'],
      comms: row['data-comments']
    }
  end
  topics[start_index..-1]
end

def is_topic_in_db(tpc, db_tpcs)
  if db_tpcs.include?(tpc[:unique_code])
    true
  else
    false
  end
end

def is_next_page(browser)
  if browser.link(class: 'show-more').present?
    true
  else
    false
  end
end

def go_next_page(browser)
  browser.link(class: 'show-more').click
  sleep(0.7)
end

def check_comments(browser, unique_code)
  this_topic = Topics[unique_code: unique_code]
  w_comments = ''
  prev_comm_id = nil

  if browser.div(class: 'flat-comments').exists?
    browser.div(class: 'pager').links.each do |pager_link|
      next unless pager_link.text

      pager_link.click
      w_comments += browser.div(class: 'flat-comments').html
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

def add_topic(browser, unique_code)
  w_topic = browser.div(class: 'op-container').html
  n_topic = Nokogiri::HTML.parse(w_topic)

  # title = n_topic.css('.discussion-title > h1 > span')[1].text
  author = n_topic.css('.username').text
  date = Time.parse(n_topic.css('.author-info > span')[0]['title'])
  # content = n_topic.css('#content').text

  Topics.create(
    comm_amount: 0,
    title: 'title',
    unique_code: unique_code,
    author: author,
    date: date,
    content: 'content'
  )

  check_comments(browser, unique_code)
end

loop do
  br.goto('https://boards.eune.leagueoflegends.com/en/')
  page = 0
  db_topics_uniq_codes = Topics.where(present: true).all.map(&:unique_code)
  topics_to_add = []
  topics_to_update = []

  until db_topics_uniq_codes.empty?
    site_topics = parse_discussion_table(br, page)
    site_topics.each_with_index do |topic, index|
      if is_topic_in_db(topic, db_topics_uniq_codes)
        topics_to_update.push(topic)
        db_topics_uniq_codes.delete(topic[:unique_code])
      elsif page.zero? && index < 10
        topics_to_add.push(topic)
      end
    end
    page += 1
    break unless is_next_page(br)

    go_next_page(br)
  end

  db_topics_uniq_codes.each do |db_tpc_unique_code|
    Topics[unique_code: db_tpc_unique_code].update(present: false)
  end

  topics_to_add.each do |tpc|
    br.goto("https://boards.eune.leagueoflegends.com/#{tpc[:href]}?show=flat")
    add_topic(br, tpc[:unique_code])
  end

  topics_to_update.each do |tpc|
    if Topics[unique_code: tpc[:unique_code]][:comm_amount] < tpc[:comms].to_i
      br.goto("https://boards.eune.leagueoflegends.com/#{tpc[:href]}?show=flat")
      check_comments(br, tpc[:unique_code])
    end
  end

  i = 0
  while i < 5
    print '.'
    sleep 2
    i += 1
  end
  print "\n"
end
