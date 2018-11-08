def add_topic(browser, db_conn, hash)
  topic = browser.div(class: 'op-container').html
  n_topic = Nokogiri::HTML.parse(topic)

  # topic_title = n_topic.css('.discussion-title > h1 > span')[1].text
  topic_author = n_topic.css('.username').text
  topic_date = n_topic.css('.author-info > span')[0]['title'][0..15].tr('T', ' ')
  # topic_content = n_topic.css('#content').text

  db_conn[:topics].insert(
    topicCommAmount: 0,
    topicTitle: 'topic_title',
    topicHash: hash,
    topicAuthor: topic_author,
    topicDate: topic_date,
    topicContent: 'topic_content'
  )

  check_comments(browser, db_conn, hash)
end
