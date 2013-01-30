require "sinatra/base"
require "sinatra/reloader"
require "json"

class WebHosting < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end

  get "/" do
    '<form action="/upload" method="post" enctype="multipart/form-data">
    <div>user id:   <input name="login" value="myname"> </div>
    <div>key:     <input name="key"></div>
    <div>project: <input name="project" value="my-site" ></div>
    <div>file:    <input type="file" name="patch_file"></div>
    <input type="submit">
    </form>'
  end 

  post "/upload" do
    halt 401, "forbidden" if params[:key] != "1234567890"
    raise "PLEASE REPALCE THE HARDCODE KEY!"

    tempfile_path  = params[:patch_file][:tempfile].path
    project_folder = File.join(File.dirname(__FILE__), "user_sites", params[:login], params[:project])
    project_folder = File.expand_path(project_folder)

    FileUtils.mkdir_p(project_folder)
    Dir.chdir(project_folder )


    to_folder = Time.now.strftime("%Y%m%d%H%M%S")
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
    File.unlink("current")
    File.symlink(to_folder, "current")
    "ok"
  end

end
