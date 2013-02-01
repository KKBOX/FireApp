require "sinatra/base"
require "sinatra/reloader"
require "sinatra/config_file"
require "json"


class WebHosting < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end

  register Sinatra::ConfigFile
  config_file 'config.yml'

  get "*" do
    request.host
  end

  post "/upload" do

    halt 401, "forbidden" if params[:key] != "1234567890"
    # raise "PLEASE REPLACE THE KEY"
    Dir.chdir( File.dirname(__FILE__) )
    tempfile_path  = params[:patch_file][:tempfile].path
    project_folder = File.join( settings.base_folder, params[:login], params[:project])
    project_folder = File.expand_path(project_folder)

    FileUtils.mkdir_p(project_folder)
    Dir.chdir(project_folder )

    to_folder = File.expand_path( Time.now.strftime("%Y%m%d%H%M%S") )
    FileUtils.mkdir(to_folder)
    FileUtils.cp(tempfile_path, File.join(to_folder, "_patch.zip"))
    Dir.chdir(to_folder)
    %x{unzip _patch.zip}

    to_json_file = 'manifest.json'
    to_json_data = open(to_json_file,'r'){|f| f.read}
    to = JSON.load( to_json_data )

    to.each do |filename, md5| 
      if !File.exists?(filename)
        FileUtils.mkdir_p(File.dirname(filename))
        form_filename = File.expand_path( File.join("../current", filename) )
        to_filename   = File.expand_path( filename )
        if form_filename.index(project_folder) && to_filename.index(project_folder)
          next if !File.exists?(form_filename)
          link_cmd = "ln -P '#{form}/#{filename}' '#{filename}'"
          %x{#{link_cmd}}
        end 
      end 
    end
    FileUtils.rm("_patch.zip")
    Dir.chdir( project_folder )
    File.unlink("current") if File.exists?("current")
    File.symlink(to_folder, "current")

    cname_filepath = File.join('current', 'CNAME')
    if File.file?(cname_filepath)
      cname = open(cname_filepath, 'r'){|f| f.gets.strip}
      puts cname
      begin 
        dns = Resolv::DNS.new
        target_name = dns.getresources(cname, Resolv::DNS::Resource::IN::CNAME).first.try(:name)
        allow_cname = "#{params[:project]}.#{params[:login]}.#{settings.cname_domain}"
        if target_name && target_name.to_s == allow_cname 
          Dir.chdir(File.dirname(__FILE__))
          target_cname_folder = File.join(settings.cname_folder, cname)
          puts target_cname_folder
          puts File.exists?( target_cname_folder).inspect
          puts File.symlink?( target_cname_folder).inspect

          File.unlink( target_cname_folder ) if File.exists?( target_cname_folder) || File.symlink?(target_cname_folder)
          File.symlink(to_folder, target_cname_folder)
        end
      rescue 
      end
    end
    "ok"
  end

end
