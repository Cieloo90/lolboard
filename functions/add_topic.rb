def add_topic(browser, db_conn, unique)
  w_topic = browser.div(class: 'op-container').html
  n_topic = Nokogiri::HTML.parse(w_topic)

  # topic_title = n_topic.css('.discussion-title > h1 > span')[1].text
  topic_author = n_topic.css('.username').text
  topic_date = n_topic.css('.author-info > span')[0]['title'][0..15].tr('T', ' ')
  # topic_content = n_topic.css('#content').text

  Topics.create(
    comm_amount: 0,
    title: 'topic_title',
    unique_code: unique,
    author: topic_author,
    date: topic_date,
    content: 'topic_content'
  )

  check_comments(browser, db_conn, unique)
end
