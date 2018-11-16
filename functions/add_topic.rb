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
