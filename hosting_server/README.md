# Project Config Example

append to config.rb 

        the_hold_options = {
          :login   => "YOUR LOGIN ID",
          :token   => "YOUR TOKEN",
          :project => "YOUR PROJECT NAME",
          :host    => "THE HOSTING SITE URL",
          :cname   => "PROJECT CNAME",
          :project_site_password => "PROJECT PASSWORD"
        }

# Nginx Config  Example 

        server {
            listen 80;
            server_name foo.bar.com *.foo,bar.com ;

            access_log /var/log/nginx/foo.bar.access.log;
            error_log /var/log/nginx/foo.bar.error.log;

            location /user_sites {
                internal;
                root /foo/bar;
            }
            location / {
                proxy_pass        http://localhost:9292;
                proxy_set_header Host $host;
            }
        }

