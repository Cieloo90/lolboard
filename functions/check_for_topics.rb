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
