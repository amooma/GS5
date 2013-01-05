# encoding: UTF-8

desc "Import inbound fax"

task :import_inbound_fax, [
    :fax_account_id,
    :result_code,
    :document_total_pages,
    :document_transferred_pages,
    :ecm_requested,
    :ecm_used,
    :image_resolution,
    :remote_station_id,
    :transfer_rate,
    :transmission_time,
    :document,
    :caller_id_number,
    :caller_id_name,
  ] => :environment do |t, a|

  TIFF_FUFFIX = ".tiff"
  PDF_SUFFIX = ".pdf"
  
  fax_arguments = a.to_hash

  tiff_file = fax_arguments[:document]

  if !tiff_file or !File.exists?( tiff_file ) 
    $stderr.puts "File \"#{tiff_file}\" does not exist"
    exit 1
  end

  paper_size = "letter"
  pdf_file = "#{File.dirname(tiff_file)}/#{File.basename(tiff_file, TIFF_FUFFIX)}#{PDF_SUFFIX}"

  system "tiff2pdf \\
    -o \"#{pdf_file}\" \\
    -p #{paper_size} \\
    -a \"#{fax_arguments[:remote_station_id]}\" \\
    -c \"AMOOMA Gemeinschaft version #{GsParameter.get('GEMEINSCHAFT_VERSION')}\" \\
    -t \"#{fax_arguments[:remote_station_id]}\" \"#{tiff_file}\""

  if !File.exists?( pdf_file ) 
    $stderr.puts "File \"#{pdf_file}\" does not exist"
    exit 1
  end

  fax_account = FaxAccount.find(fax_arguments[:fax_account_id])
  if !fax_account
    $stderr.puts "Fax account \"#{fax_arguments[:fax_account_id]}\" does not exist"
    exit 1
  end
  
  fax_arguments[:document]          = nil
  fax_arguments[:success]           = true
  fax_arguments[:inbound]           = true
  fax_arguments[:sent_at]           = Time.now
  fax_arguments[:local_station_id]  = fax_account.station_id
  fax_arguments[:retry_counter]     = 0
  fax_arguments[:fax_resolution_id] = FaxResolution.first.id
  fax_arguments[:image_size]        = File.size(tiff_file)
  fax_arguments[:ecm_used]          = fax_arguments[:ecm_used] == "on" ? true : false
  fax_document = fax_account.fax_documents.build(fax_arguments)
  fax_document.document = File.open(pdf_file)

  if fax_document.save
    fax_document.mark_as_inbound!
    exit 0
  else
    $stderr.puts "Error(s) creating fax document:"
    $stderr.puts fax_document.errors.inspect
    exit 1
  end
end
