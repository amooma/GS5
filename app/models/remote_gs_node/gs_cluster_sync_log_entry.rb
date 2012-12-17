# Find docu about ActiveResource at 
# http://ofps.oreilly.com/titles/9780596521424/activeresource_id59243.html
# test = RemoteGSNode::GcLogEntry.first.attributes.delete_if{|key, value| ['id','updated_at','created_at'].include?(key) })

module RemoteGsNode
  class GsClusterSyncLogEntry < ActiveResource::Base
    self.site = 'http://0.0.0.0:3000'
  end
end