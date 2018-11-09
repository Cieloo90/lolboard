def check_comments(browser, db_conn, unique)
  this_topic_id = Topics[unique_code: unique][:id]
  comments_ammount = 0
  prev_comm_id = nil

  if browser.div(class: 'flat-comments').exists?
    # browser.div(class: 'pager').link().each do |pager_link|
    #   pager_link.click
    w_comments = browser.div(class: 'flat-comments').html
    # end
    n_comments = Nokogiri::HTML.parse(w_comments)

    ### \/ to do - pagination on comments site \/ ###

    n_comments.css('.nested-comment').each do |comm|
      comments_ammount += 1
      comm_inner_id = comm['id']
      comm_date = comm.css('.timeago > span')[0]['title'][0..18].tr('T', ' ')

      comm_exist = Comments[inner_id: comm_inner_id, date: comm_date]

      if comm_exist
        prev_comm_id = comm_exist[:id]

      else
        new_comm = Comments.create(
          topic_id: prev_comm_id ? 0 : this_topic_id,
          prev_comm_id: prev_comm_id || 0,
          inner_id: comm_inner_id,
          author: 'comm_author',
          date: comm_date,
          content: 'comm_content'
        )

        unless prev_comm_id
          first_comm_id = Comments[topic_id: this_topic_id, prev_comm_id: 0][:id]
          Topics[id: this_topic_id].set(first_comm: first_comm_id)
        end
        prev_comm_id = new_comm[:id]
      end
    end
  end
  Topics[id: this_topic_id].set(comm_amount: comments_ammount)
end
