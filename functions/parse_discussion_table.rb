def parse_discussion_table(browser)
  n_discussion_table = Nokogiri::HTML.parse(browser.div(class: %w[discussions main]).html)

  topics = n_discussion_table.css('.discussion-list-item').map do |row|
    {
      href: row['data-href'],
      unique_code: row['data-discussion-id'],
      comms: row['data-comments']
    }
  end
  topics
end
