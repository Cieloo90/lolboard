def remain_db_topics(site_tpcs)
  db_tpcs = []
  Topics.each do |tpc|
    db_tpcs.push(tpc) if tpc[:present] == true
  end
  site_tpcs.each do |site_tpc|
    if db_tpcs.include?(Topics[unique_code: site_tpc[:unique_code]])
      db_tpcs.delete(Topics[unique_code: site_tpc[:unique_code]])
    end
  end
  db_tpcs
end
