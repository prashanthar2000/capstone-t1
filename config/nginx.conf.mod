
user nginx;
worker_processes  3;
error_log  /var/log/nginx/error.log;
events {
    worker_connections  10240;
}
http {
    log_format  main
            'remote_addr:$remote_addr\t'
            'time_local:$time_local\t'
            'method:$request_method\t'
            'uri:$request_uri\t'
            'host:$host\t'
            'status:$status\t'
            'bytes_sent:$body_bytes_sent\t'
            'referer:$http_referer\t'
            'useragent:$http_user_agent\t'
            'forwardedfor:$http_x_forwarded_for\t'
            'request_time:$request_time';
    access_log	/var/log/nginx/access.log main;
    
    
    upstream api-server {
        server api-service:8080;
        keepalive 1024;
    }
    server {
        # listen 8080 default_server;
        listen 8080 ssl; 
        server_name capstone-demo.ddns.net;
        ssl_certificate /etc/letsencrypt/live/capstone-demo.ddns.net/fullchain.pem; 
        ssl_certificate_key /etc/letsencrypt/live/capstone-demo.ddns.net/privkey.pem; 
        include /etc/letsencrypt/options-ssl-nginx.conf; 
        ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; 


        location / {
            proxy_pass http://api-server/;
        }
    }

    upstream frontend-server {
        server frontend-service:8081;
        keepalive 1024;
    }

    server {
        # listen 8081;
        listen 8081 ssl; 
        server_name capstone-demo.ddns.net;
        ssl_certificate /etc/letsencrypt/live/capstone-demo.ddns.net/fullchain.pem; 
        ssl_certificate_key /etc/letsencrypt/live/capstone-demo.ddns.net/privkey.pem; 
        include /etc/letsencrypt/options-ssl-nginx.conf; 
        ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
        
        
        location / {
            proxy_pass http://frontend-server/;

        }
    }

    upstream mchat-server {
        server mchat-service:8065;
        keepalive 1024;
    }

    server {
        # listen 8065;
        listen 8065 ssl; 
        server_name capstone-demo.ddns.net;
        ssl_certificate /etc/letsencrypt/live/capstone-demo.ddns.net/fullchain.pem; 
        ssl_certificate_key /etc/letsencrypt/live/capstone-demo.ddns.net/privkey.pem; 
        include /etc/letsencrypt/options-ssl-nginx.conf; 
        ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;


        location / {
            proxy_pass http://mchat-server/;

        }
    }

}