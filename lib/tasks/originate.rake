desc "Originate call"

task :originate, [
    :sip_account_id,
    :extension,
  ] => :environment do |t, a|

  extension = a.extension.to_s
  sip_account = SipAccount.where(:id => a.sip_account_id.to_i).first

  print "Originate #{sip_account} -> #{extension} ... "
  puts sip_account.call(extension, nil, nil, true)
end
