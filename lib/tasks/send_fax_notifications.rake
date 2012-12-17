# encoding: UTF-8

desc "Import inbound fax"

task :send_fax_notifications => :environment do
  FaxDocument.where(:state => 'received').each do |fax_document|
    TIFF_FUFFIX = ".tiff"
    PDF_SUFFIX = ".pdf"
    TMP_DIR = "/tmp/"

    tiff_file = File.basename(fax_document.tiff.to_s)

    if !File.exists?( "#{TMP_DIR}#{tiff_file}" ) 
      fax_document.state = 'unsuccessful'
      fax_document.save
      next
    end

    paper_size = "letter"
    pdf_file = "#{TMP_DIR}#{File.basename(tiff_file, TIFF_FUFFIX)}#{PDF_SUFFIX}"

    system "tiff2pdf \\
      -o \"#{pdf_file}\" \\
      -p #{paper_size} \\
      -a \"#{fax_document.remote_station_id}\" \\
      -c \"AMOOMA Gemeinschaft version #{GEMEINSCHAFT_VERSION}\" \\
      -t \"#{fax_document.remote_station_id}\" \"#{TMP_DIR}#{tiff_file}\""

    if !File.exists?( pdf_file ) 
      fax_document.state = 'unsuccessful'
      fax_document.save
      next
    end

    fax_document.document = File.open(pdf_file)
    fax_document.state = 'successful'
    
    if fax_document.save
      Notifications.new_fax(fax_document).deliver
      File.delete("#{TMP_DIR}#{tiff_file}");
      File.delete(pdf_file);
      fax_document.tiff = nil
      fax_document.save
    else
      fax_document.state = 'unsuccessful'
      fax_document.save
    end
  end
end
