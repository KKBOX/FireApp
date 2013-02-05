require 'bundler'

Bundler.require

require 'rack'
require 'rack/mime'
require 'rack/contrib'
require 'redis' 
require 'yaml'
require 'json'


class TheHoldApp
  def initialize
    @base_path = "user_sites"
    @cname_domain = "the-hold.handlino.com"   
    @redis = Redis.new
  end

  def call(env)
    req = Rack::Request.new(env)
 
    site_key = "site-" + env["HTTP_HOST"].split(/:/).first
    site   = @redis.hgetall(site_key)
    return upload_file(req.params) if env["PATH_INFO"] == '/upload' && req.post?
    return not_found               if !( site["login"] && site["project"] && env["PATH_INFO"] != '/AUTH' )
       
    current_project_path = File.join(@base_path, site["login"], site["project"], "current")
    if site["project_site_password"] && env["PATH_INFO"] != "/manifest.json"

      if req.post? && site["project_site_password"] == req.params["password"]
          env["rack.session"]["password"]= req.params["password"]
      end

      if site["project_site_password"] != env["rack.session"]["password"]
        return login(env)
      end
    end
    
    path_info    = env["PATH_INFO"][-1] == '/' ? "#{env["PATH_INFO"]}index.html" : env["PATH_INFO"]

    if File.extname(path_info) == ""
      path_info += "/index.html" if File.directory?(  File.join( File.dirname(__FILE__), current_project_path,  path_info ) )
    end

    redirect_url = File.join(  "/", current_project_path,  path_info )
    mime_type = Rack::Mime.mime_type(File.extname(redirect_url), "text/html")
    [200, {"Cache-Control" => "no-cache, no-store", 'Content-Type' => mime_type, 'X-Accel-Redirect' => redirect_url }, []]
  end


  def upload_file(params)
    user_token_key = "user-#{params["login"]}"
    user_token  = @redis.get(user_token_key)
    return forbidden  unless user_token && user_token  == params["token"]

    Dir.chdir( File.dirname(__FILE__) )
    tempfile_path  = params["patch_file"][:tempfile].path
    project_folder = File.join( @base_path, params["login"], params["project"])
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
          File.link(form_filename, filename)
        end 
      end 
    end
    FileUtils.rm("_patch.zip")
    Dir.chdir( project_folder )
    File.unlink("current") if File.exists?("current")
    File.symlink(to_folder, "current")

    project_hostname = "#{params["project"]}.#{params["login"]}.#{@cname_domain}"
    @redis.hmset("site-#{project_hostname}", :login, params["login"], :project, params["project"] );

    if params["cname"]
      cname = params["cname"]
      begin 
        dns = Resolv::DNS.new
        target_name = dns.getresources(cname, Resolv::DNS::Resource::IN::CNAME).first.try(:name)
        if target_name && target_name.to_s == project_hostname
          @redis.hmset("site-#{cname}",       :login, params["login"], :project, params["project"] );
        end
      end
    end
    
    if params["project_site_password"]
      password = params["project_site_password"][0,64]
      @redis.hset("site-#{cname}", "project_site_password", password ) if cname
      @redis.hset("site-#{project_hostname}", 'project_site_password', password);
    else
      @redis.hdel("site-#{cname}", "project_site_password" ) if cname
      @redis.hdel("site-#{project_hostname}", 'project_site_password');
    end

    [200, {"Content-Type" => "text/plain"}, ["ok"]]
  end

  def not_found
    [404, {'Content-Type' => 'text/plain' }, ["Not Fonud"]]
  end
 
  def forbidden
    [403, {'Content-Type' => 'text/plain' }, ["Forbidden"]]
  end

  def login(env)
    [200, { "Content-Type" => "text/html" }, [<<EOL
      <html>
      <body>
      <form action="#{env["PATH_INFO"]}" method="post">
    password:<input type="password" name="password">
    <input type="submit">
    </form>
    </body>
    </html>
EOL
    ]]
  end

end

use Rack::Session::Cookie, :secret => 'SECRET TOKEN'
raise "replace SECRET TOKEN"

run TheHoldApp.new

