#! /bin/bash

######################################################################
########################    GREAT RESOURCE    ########################
######################################################################

# should adjust this script to this link
# https://blog.cloudboost.io/setting-up-an-https-sever-with-node-amazon-ec2-nginx-and-lets-encrypt-46f869159469


######################################################################
########################     HOW TO USE     ##########################
######################################################################

# 1. run this script `source deploy-backend.sh`
# 2. create virtualenv and install requirements 
#         `virtualenv -p python3 ~/book-recommender-api/venv`
#         `source ~/book-recommender-api/venv/bin/activate`
#         `pip3 install -r requirements.txt`
# 3. use launch script or run gunicorn command `gunicorn app:app --daemon`

# Notes about checking current running processes (gunicorn processes)
# 1. check running gunicorn processes `pgrep -f gunicorn`
# 1. kill running gunicorn processes `pkill -f gunicorn`

function initialize_worker() {
    printf "***************************************************\n\t\tSetting up host \n***************************************************\n"
    # Update packages
    echo ======= Updating packages ========
    sudo apt-get update

    # Export language locale settings
    echo ======= Exporting language locale settings =======
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8

    # Install pip3
    echo ======= Installing pip3 =======
    sudo apt-get install -y python3-pip
}

function setup_python_venv() {
    printf "***************************************************\n\t\tSetting up Venv \n***************************************************\n"
    # Install virtualenv
    echo ======= Installing virtualenv =======
    pip3 install virtualenv

    # Create virtual environment and activate it
    echo ======== Creating and activating virtual env =======
    virtualenv -p python3 ~/book-recommender-api/venv
    source ~/book-recommender-api/venv/bin/activate
}

function clone_app_repository() {
    printf "***************************************************\n\t\tFetching App \n***************************************************\n"
    # Clone and access project directory
    echo ======== Cloning and accessing project directory ========
    if [[ -d ~/book-recommender-api ]]; then
        sudo rm -rf ~/book-recommender-api
        git clone https://github.com/bendevera/book-recommender-api.git ~/book-recommender-api
        cd ~/book-recommender-api/
    else
        git clone https://github.com/bendevera/book-recommender-api.git ~/book-recommender-api
        cd ~/book-recommender-api/
    fi
}

function setup_app() {
    printf "***************************************************\n    Installing App dependencies and Env Variables \n***************************************************\n"
    # Install required packages
    echo ======= Installing required packages ========
    pip3 install -r requirements.txt

}

# Create and Export required environment variable
function setup_env() {
    echo ======= Exporting the necessary environment variables ========
    sudo cat > ~/.env << EOF
    export APP_CONFIG="production"
    export SECRET_KEY="mYd3rTyL!tTl#sEcR3t"
    export FLASK_APP=manage.py
EOF
    echo ======= Exporting the necessary environment variables ========
    source ~/.env
}

function setup_nginx() {
    printf "***************************************************\n\t\tSetting up nginx \n***************************************************\n"
    echo ======= Installing nginx =======
    sudo wget http://nginx.org/keys/nginx_signing.key
    sudo apt-key add nginx_signing.key
    echo ======= Append to sources.list =======
    sudo bash -c 'cat <<EOF >> /etc/apt/sources.list
    # 
    deb http://nginx.org/packages/ubuntu xenial nginx
    deb-src http://nginx.org/packages/ubuntu xenial nginx
    #
EOF'
    sudo apt-get update
    sudo apt-get install nginx
    sudo service nginx start
}

function setup_ssl () {
    printf "***************************************************\n\t\tSetting up SSL \n***************************************************\n"
    sudo apt-get update
    sudo apt-get install software-properties-common
    sudo add-apt-repository ppa:certbot/certbot
    sudo apt-get update
    sudo apt-get install python-certbot-nginx

}

# need to change nginx config file:
# sudo nano /etc/nginx/conf.d/default.conf
# Next to “server_name”, replace “localhost” with your domain(s)
# sudo certbot --nginx -d <domain1 string> -d <domainN string>
#

function setup_ssl_two () {
    printf "***************************************************\n\t\tSetting up SSL2 \n***************************************************\n"
    cd /etc/nginx/conf.d
    sudo mv default.conf default.conf.bak
    sudo touch server.conf
    sudo bash -c 'cat <<EOF > server.conf
    server {
    listen 80;
    listen [::]:80;
    server_name api.mnistalgotoy.com;
    return 301 https://$server_name$request_uri;
    }
    server {
    listen 443 ssl http2 default_server;
    listen [::]:443 ssl http2 default_server;
    server_name api.mnistalgotoy.com;
    location / {
    proxy_pass http://localhost:3000;
    }
    ssl_certificate /etc/letsencrypt/live/api.mnistalgotoy.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.mnistalgotoy.com/privkey.pem;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_ciphers EECDH+CHACHA20:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;
    ssl_session_cache shared:SSL:5m;
    ssl_session_timeout 1h;
    add_header Strict-Transport-Security “max-age=15768000” always;
    }
EOF'
    sudo nginx -s reload
}

# Add a launch script
# source ~/book-recommender-api/venv/bin/activate
function create_launch_script () {
    printf "***************************************************\n\t\tCreating a Launch script \n***************************************************\n"

    sudo cat > /home/ubuntu/launch.sh <<EOF
    #!/bin/bash
    cd ~/book-recommender-api
    source ~/.env
    gunicorn app:app --daemon
EOF
    sudo chmod 744 /home/ubuntu/launch.sh
    echo ====== Ensuring script is executable =======
    ls -la ~/launch.sh
}


######################################################################
########################      RUNTIME       ##########################
######################################################################

initialize_worker
setup_python_venv
clone_app_repository
setup_env
setup_app
setup_nginx # need to cross reference with blog
# setup_ssl
# create_launch_script # will most likely do this manually




printf "***************************************************\n\t\tDONE \n***************************************************\n"