# The Gemeinschaft version is stored in an environment variable.
# It equals the branch in git.
#
if !ENV['GS_VERSION'].nil? && GsParameter.table_exists? && GsParameter.get('GEMEINSCHAFT_VERSION') != ENV['GS_VERSION']
  version = GsParameter.find_or_create_by_name('GEMEINSCHAFT_VERSION')
  version.section = 'Generic'
  version.value = ENV['GS_VERSION']
  version.save
end

if !ENV['GS_BUILDNAME'].nil? && GsParameter.table_exists? && GsParameter.get('GS_BUILDNAME') != ENV['GS_BUILDNAME']
  buildname = GsParameter.find_or_create_by_name('GEMEINSCHAFT_BUILDNAME')
  buildname.section = 'Generic'
  buildname.value = ENV['GS_BUILDNAME']
  buildname.save
end
