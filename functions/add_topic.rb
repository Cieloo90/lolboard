def add_topic(browser, db_conn, hash)
  topic = browser.div(class: 'op-container').html
  n_topic = Nokogiri::HTML.parse(topic)
  if browser.div(class: 'list').exists?
    comments = browser.div(class: 'list').html
    n_comments = Nokogiri::HTML.parse(comments)
  end

  # topic_title = n_topic.css('.discussion-title > h1 > span')[1].text
  topic_author = n_topic.css('.username').text
  topic_date = n_topic.css('.author-info > span')[0]['title'][0..15].tr('T', ' ')
  # topic_content = n_topic.css('#content').text

  comments_amount = if comments
                      n_comments.css('.nested-comment').count
                    else
                      0
                    end

  db_conn[:topics].insert(
    topicCommAmount: comments_amount,
    topicTitle: 'topic_title',
    topicHash: hash,
    topicAuthor: topic_author,
    topicDate: topic_date,
    topicContent: 'topic_content'
  )
  this_topic_id = db_conn[:topics].where(topicHash: hash).get(:topicId)

  if comments_amount.zero?
    db_conn[:topics].where(topicId: this_topic_id).update(topicFirstComm: 0)
    puts 'no comments in topic'
  else
    n_comments.css('.nested-comment').each_with_index do |comm, index|
      comm_inner_id = comm['id']
      # comm_author = comm.css('a.profile-hover').text
      comm_date = comm.css('.timeago > span')[0]['title'][0..15].tr('T', ' ')
      # comm_content = comm.css('.body').text

      if index.zero?
        db_conn[:comments].insert(
          commTopicId: this_topic_id,
          commPrevComm: 0,
          commInnerId: comm_inner_id,
          commAuthor: 'comm_author',
          commDate: comm_date,
          commContent: 'comm_content'
        )
        this_comm_id = db_conn[:comments].where(commTopicId: this_topic_id, commPrevComm: 0).get(:commId)
        db_conn[:topics].where(topicId: this_topic_id).update(topicFirstComm: this_comm_id)
      else
        # db_conn[:comments].insert()
      end
    end
  end
end