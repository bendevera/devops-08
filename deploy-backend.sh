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
#         `virtualenv -p python3 ~/MNIST-ML-Algos-API/venv`
#         `source ~/MNIST-ML-Algos-API/venv/bin/activate`
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
    virtualenv -p python3 ~/MNIST-ML-Algos-API/venv
    source ~/MNIST-ML-Algos-API/venv/bin/activate
}

function clone_app_repository() {
    printf "***************************************************\n\t\tFetching App \n***************************************************\n"
    # Clone and access project directory
    echo ======== Cloning and accessing project directory ========
    if [[ -d ~/MNIST-ML-Algos-API ]]; then
        sudo rm -rf ~/MNIST-ML-Algos-API
        git clone https://github.com/bendevera/MNIST-ML-Algos-API.git ~/MNIST-ML-Algos-API
        cd ~/MNIST-ML-Algos-API/
    else
        git clone https://github.com/bendevera/MNIST-ML-Algos-API.git ~/MNIST-ML-Algos-API
        cd ~/MNIST-ML-Algos-API/
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
    export FLASK_APP=ml_algos_api.py
EOF
    echo ======= Exporting the necessary environment variables ========
    source ~/.env
}

# Install and configure nginx
function setup_nginx() {
    printf "***************************************************\n\t\tSetting up nginx \n***************************************************\n"
    echo ======= Installing nginx =======
    sudo apt-get install -y nginx

    # Configure nginx routing
    echo ======= Configuring nginx =======
    echo ======= Removing default config =======
    sudo rm -rf /etc/nginx/sites-available/default
    sudo rm -rf /etc/nginx/sites-enabled/default
    echo ======= Replace config file =======
    sudo bash -c 'cat <<EOF > /etc/nginx/sites-available/default
    server {
            listen 80 default_server;
            listen [::]:80 default_server;

            server_name _;

            location / {
                    # reverse proxy and serve the app
                    # running on the localhost:8000
                    proxy_pass http://127.0.0.1:8000/;
                    proxy_set_header HOST \$host;
                    proxy_set_header X-Forwarded-Proto \$scheme;
                    proxy_set_header X-Real-IP \$remote_addr;
                    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            }
    }
EOF'

    echo ======= Create a symbolic link of the file to sites-enabled =======
    sudo ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

    # Ensure nginx server is running
    echo ====== Checking nginx server status ========
    sudo systemctl restart nginx
    sudo nginx -t
}

# Add a launch script
# source ~/MNIST-ML-Algos-API/venv/bin/activate
function create_launch_script () {
    printf "***************************************************\n\t\tCreating a Launch script \n***************************************************\n"

    sudo cat > /home/ubuntu/launch.sh <<EOF
    #!/bin/bash
    cd ~/MNIST-ML-Algos-API
    source ~/.env
    gunicorn app:app -D
EOF
    sudo chmod 744 /home/ubuntu/launch.sh
    echo ====== Ensuring script is executable =======
    ls -la ~/launch.sh
}

function configure_startup_service () {
    printf "***************************************************\n\t\tConfiguring startup service \n***************************************************\n"

    sudo bash -c 'cat > /etc/systemd/system/yummy-rest.service <<EOF
    [Unit]
    Description=yummy-rest startup service
    After=network.target

    [Service]
    User=ubuntu
    ExecStart=/bin/bash /home/ubuntu/launch.sh

    [Install]
    WantedBy=multi-user.target
EOF'

    sudo chmod 664 /etc/systemd/system/yummy-rest.service
    sudo systemctl daemon-reload
    sudo systemctl enable yummy-rest.service
    sudo systemctl start yummy-rest.service
    sudo service yummy-rest status
}

Serve the web app through gunicorn
function launch_app() {
    printf "***************************************************\n\t\tServing the App \n***************************************************\n"
    sudo bash /home/ubuntu/launch.sh
}

######################################################################
########################      RUNTIME       ##########################
######################################################################

initialize_worker
# setup_python_venv
clone_app_repository
setup_env
# setup_app
setup_nginx
create_launch_script
configure_startup_service
# launch_app




printf "***************************************************\n\t\tDONE \n***************************************************\n"