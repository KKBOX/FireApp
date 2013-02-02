
require "digest/md5"
require "json"
require "zip/zip"
require 'net/http/post/multipart'
require "tempfile"
class TheHoldUploader

  def self.build_manifest(folder_path)
    pwd = Dir.pwd 

    Dir.chdir( folder_path )

    manifest = {}
    Dir.glob(File.join("**", "*")) do | filename |
      next if File.directory?(filename)
    md5sum = Digest::MD5.hexdigest( open(filename, 'r'){|f| f.read })
    manifest[filename]= md5sum
    end

    open("manifest.json", "w"){|f| f.write( JSON.dump(manifest) )}

    Dir.chdir(pwd)
  end 



  def self.upload_patch(to_folder, options)

    begin 
      form = JSON.load( open("http://#{options[:project]}.#{options[:login]}.#{options[:host]}/manifest.json",'r'){|f| f.read} )
    rescue
      form = {}
    end

    self.build_manifest(to_folder)

    to_json_file = File.join(to_folder, 'manifest.json')
    to_json_data = open(to_json_file,'r'){|f| f.read}
    to = JSON.load( to_json_data )

    tempfile = File.join( Dir.tmpdir,"the-hold-#{options[:project]}-#{rand}.zip")
    Zip::ZipOutputStream.open(tempfile) do |zos|
      zos.put_next_entry 'manifest.json'
      zos.puts to_json_data

      to.each do |filename, md5| 
        puts filename
        if form[filename] != md5 
          zos.put_next_entry filename
          zos.puts open( File.join(to_folder, filename), 'r'){|f| f.read}
        end
      end
    end

    url = URI.parse("#{options[:host]}/upload")
    tempfile_io = open(tempfile)
    req = Net::HTTP::Post::Multipart.new url.path,
      "patch_file" => UploadIO.new(tempfile_io, "application/zip", "patch_file.zip"),
      "login"      => options[:login],
      "token"        => options[:token],
      "project"    => options[:project]
    respone = Net::HTTP.start(url.host, url.port) do |http|
      http.request(req)
    end
    tempfile_io.close
    File.unlink(tempfile)
    puts respone.inspect
    respone
  end

end 
