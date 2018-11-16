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
