def check_comments(browser, db_conn, hash)
  this_topic_id = db_conn[:topics].where(unique_code: hash).get(:id)
  comments_ammount = 0
  prev_comm_id = nil

  if browser.div(class: 'flat-comments').exists?
    # browser.div(class: 'pager').link().each do |pager_link|
    #   pager_link.click
    comments = browser.div(class: 'flat-comments').html
    # end
    n_comments = Nokogiri::HTML.parse(comments)

    ### \/ to do - pagination on comments site \/ ###

    n_comments.css('.nested-comment').each do |comm|
      comments_ammount += 1
      comm_inner_id = comm['id']
      comm_date = comm.css('.timeago > span')[0]['title'][0..18].tr('T', ' ')

      comm_check = db_conn[:comments].where(
        inner_id: comm_inner_id,
        date: comm_date
      )

      if comm_check.count > 0
        prev_comm_id = comm_check.get(:id)

      else
        db_conn[:comments].insert(
          topic_id: prev_comm_id ? 0 : this_topic_id,
          prev_comm_id: prev_comm_id || 0,
          inner_id: comm_inner_id,
          author: 'comm_author',
          date: comm_date,
          content: 'comm_content'
        )

        unless prev_comm_id
          first_comm_id = db_conn[:comments].where(
            topic_id: this_topic_id,
            prev_comm_id: 0
          ).get(:id)

          db_conn[:topics].where(id: this_topic_id).update(
            first_comm: first_comm_id
          )
        end
        prev_comm_id = db_conn[:comments].order(Sequel.desc(:id)).get(:id)
      end
    end
  else
    puts 'no comments'
  end
  db_conn[:topics].where(id: this_topic_id).update(
    comm_amount: comments_ammount
  )
end
