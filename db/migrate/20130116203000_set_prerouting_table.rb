class SetPreroutingTable < ActiveRecord::Migration
  def up
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^%*0%*$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^%*0%*$', :replacement => 'f-li', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^%*0%*(%d+)#*$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^%*0%*(%d+)#*$', :replacement => 'f-li-%1', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^%*0%*(%d+)%*(%d+)#*$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^%*0%*(%d+)%*(%d+)#*$', :replacement => 'f-li-%1-%2', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^#0#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^#0#$', :replacement => 'f-lo', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^%*5%*(%d+)#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^%*5%*(%d+)#$', :replacement => 'f-acdmtg-0-%1', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^%*30#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^%*30#$', :replacement => 'f-clipon', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^#30#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^#30#$', :replacement => 'f-clipoff', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^%*31#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^%*31#$', :replacement => 'f-cliroff', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^#31#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^#31#$', :replacement => 'f-cliron', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^%*31#(%d+)$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^%*31#(%d+)$', :replacement => 'f-dcliroff-%1', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^#31#(%d+)$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^#31#(%d+)$', :replacement => 'f-dcliron-%1', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^%*43#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^%*43#$', :replacement => 'f-cwaon', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^#43#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^#43#$', :replacement => 'f-cwaoff', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^#002#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^#002#$', :replacement => 'f-cfoff', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^##002#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^##002#$', :replacement => 'f-cfdel', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^%*21#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^%*21#$', :replacement => 'f-cfu', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^%*21%*(%d+)#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^%*21%*(%d+)#$', :replacement => 'f-cfu-%1', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^%*%*21%*(%d+)#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^%*%*21%*(%d+)#$', :replacement => 'f-cfu-%1', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^#21#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^#21#$', :replacement => 'f-cfuoff', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^##21#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^##21#$', :replacement => 'f-cfudel', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^%*61#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^%*61#$', :replacement => 'f-cfn', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^%*61%*(%d+)#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^%*61%*(%d+)#$', :replacement => 'f-cfn-%1', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^%*%*61%*(%d+)#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^%*%*61%*(%d+)#$', :replacement => 'f-cfn-%1', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^%*61%*(%d+)%*(%d+)#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^%*61%*(%d+)%*(%d+)#$', :replacement => 'f-cfn-%1-%2', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^%*%*61%*(%d+)%*(%d+)#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^%*%*61%*(%d+)%*(%d+)#$', :replacement => 'f-cfn-%1-%2', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^#61#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^#61#$', :replacement => 'f-cfnoff', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^##61#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^##61#$', :replacement => 'f-cfndel', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^%*62#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^%*62#$', :replacement => 'f-cfo', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^%*62%*(%d+)#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^%*62%*(%d+)#$', :replacement => 'f-cfo-%1', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^%*%*62%*(%d+)#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^%*%*62%*(%d+)#$', :replacement => 'f-cfo-%1', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^#62#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^#62#$', :replacement => 'f-cfooff', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^##62#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^##62#$', :replacement => 'f-cfodel', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^%*67#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^%*67#$', :replacement => 'f-cfb', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^%*67%*(%d+)#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^%*67%*(%d+)#$', :replacement => 'f-cfb-%1', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^%*%*67%*(%d+)#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^%*%*67%*(%d+)#$', :replacement => 'f-cfb-%1', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^#67#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^#67#$', :replacement => 'f-cfboff', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^##67#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^##67#$', :replacement => 'f-cfbdel', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^%*66#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^%*66#$', :replacement => 'f-redial', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^%*98$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^%*98$', :replacement => 'f-vmcheck', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^%*98#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^%*98#$', :replacement => 'f-vmcheck', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^%*98%*(%d+)#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^%*98%*(%d+)#$', :replacement => 'f-vmcheck-%1', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^%*1337%*1%*1#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^%*1337%*1%*1#$', :replacement => 'f-loaon', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'feature code ^%*1337%*1%*0#$', :endpoint_type => 'dialplanfunction').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^%*1337%*1%*0#$', :replacement => 'f-loaoff', :action => 'set_route_var', :mandatory => true)

    CallRoute.create(:routing_table => 'prerouting', :name => 'international prefix', :endpoint_type => 'phonenumber').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^00(%d+)$', :replacement => '+%1', :action => 'set_route_var', :mandatory => true)
    CallRoute.create(:routing_table => 'prerouting', :name => 'national prefix', :endpoint_type => 'phonenumber').route_elements.
    create(:var_in => 'destination_number', :var_out => 'destination_number', :pattern => '^0(%d+)$', :replacement => '+49%1', :action => 'set_route_var', :mandatory => true)
  end

  def down
  	CallRoute.where(:routing_table => "prerouting").destroy_all
  end
end
