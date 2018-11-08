def check_comments(browser, db_conn, hash)
  this_topic_id = db_conn[:topics].where(topicHash: hash).get(:topicId)
  comments_ammount = 0
  prev_comm_id = 0

  if browser.div(class: 'flat-comments').exists?
    comments = browser.div(class: 'flat-comments').html
    n_comments = Nokogiri::HTML.parse(comments)

    ### \/ to do - pagination on comments site \/ ###

    n_comments.css('.nested-comment').each do |comm|
      comments_ammount += 1
      comm_inner_id = comm['id']
      comm_date = comm.css('.timeago > span')[0]['title'][0..18].tr('T', ' ')

      comm_check = db_conn[:comments].where(
        commInnerId: comm_inner_id,
        commDate: comm_date
      )

      if comm_check.count > 0
        prev_comm_id = comm_check.get(:commId)

      elsif comm_check.count.zero? && last_comm_id > 0
        # rest of comments
        db_conn[:comments].insert(
          commTopicId: 0,
          commPrevCommId: prev_comm_id,
          commInnerId: comm_inner_id,
          commAuthor: 'comm_author',
          commDate: comm_date,
          commContent: 'comm_content'
        )
        puts 'added recent comments'
        # to do - \/ add actual commId \/
        prev_comm_id = 1234567890
      else
        # first comment of the topic
        db_conn[:comments].insert(
          commTopicId: this_topic_id,
          commPrevCommId: 0,
          commInnerId: comm_inner_id,
          commAuthor: 'comm_author',
          commDate: comm_date,
          commContent: 'comm_content'
        )
        first_comm_id = db_conn[:comments].where(
          commTopicId: this_topic_id,
          commPrevComm: 0
        ).get(:commId)

        prev_comm_id = first_comm_id

        db_conn[:topics].where(topicId: this_topic_id).update(
          topicFirstComm: first_comm_id
        )
      end
    end
  else
    puts 'no comments'
  end
  db_conn[:topics].where(topicId: this_topic_id).update(
    topicCommAmount: comments_ammount
  )
end
