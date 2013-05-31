class AddPerimeterReportUrl < ActiveRecord::Migration
  def up
    GsParameter.create(:entity => 'perimeter', :section => 'general', :name => 'report_url', :value => 'http://fire-support.herokuapp.com/intruders/{received_ip}/report.xml?serial={serial}&blacklisted={blacklisted}&suspicious=true', :class_type => 'String', :description => '')
  end

  def down
  	GsParameter.where(:entity => 'perimeter', :section => 'general', :name => 'report_url').destroy_all
  end
end
