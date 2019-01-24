# Install the git package provided by WANdisco
function fn_install_pacakge_wandisco_git() {
    # WANdisco git variables
    wandiscoGitRepoFile=wandisco-git.repo
    wandiscoGitFileDest=/etc/yum.repos.d/ # Location to store the .repo file for yum
    wandiscoGitRpmGpgKeyLink=http://opensource.wandisco.com/RPM-GPG-KEY-WANdisco # Link to the RPM GPG key

    if [ ! -f $wandiscoGitRepoFile ]; then
        echo "Error: Failed to install git, missing required file: $wandiscoGitRepoFile" # TODO decide whether file checks should be performed per function ######
    else
        echo "Installing git..." &&
        mv -f wandisco-git.repo $wandiscoGitRepoFilePath && # Add repo to yum
        rpm --import $wandiscoGitRpmGpgKeyLink && # Import GPG key into RPM
        yum install -y git Install git && # Install git
        echo "Git Version: " &&
        git --version &&
        echo "Installed git!"
    fi
}

# Install the NGINX package, as well as the required EPEL package
function fn_install_package_nginx() {
    echo "Installing nginx..." &&
    yum install -y epel-release && # Install EPEL package
    yum install -y nginx && # Install NGINX

    nginxVersionCheckOutput="$(nginx -v)" # Simply check installation success based on version output
    if [ $nginxVersionCheckOutput ]; then
        echo "NGINX Version: $nginxVersionCheckOutput" &&
        echo "Installed NGINX!"
    else
        echo "NGINX installation appears to have failed!"
    fi
}

# Install the Node.js & npm package provided by nodesource.com, as well as dependencies
function fn_install_package_nodejs() {
    echo "Installing Node.js..." &&
    yum install -y gcc-c++ make && # Install dependencies
    curl -sL https://rpm.nodesource.com/setup_10.x | bash - && # Add nodesource repo
    yum install -y nodejs && # Install Node.js

    nodejsVersionOutput="$(node -v)" &&
    npmVersionOutput="$(npm -v)" &&
    if [ $nodejsVersionOutput && $npmVersionOutput ]; then
        echo "Node.js Version: $nodejsVersionOutput" &&
        echo "NPM Version: $npmVersionOutput" &&
        echo "Installed Node.js!"
    else
        echo "Node.js installation appears to have failed!"
    fi
}

# Install the PM2 NPM package
function fn_install_package_pm2() {
    echo "Installing PM2..." &&
    npm install -g PM2 && # Install PM2

    pm2VersionCheckOutput="$(pm2 --version)" # Simply check installation success based on version output
    if [ $pm2VersionCheckOutput ]; then
        echo "PM2 Version: $pm2VersionCheckOutput" &&
        echo "Installed PM2!"
    else
        echo "PM2 installation appears to have failed!"
    fi
}

# Stop, disable, and remove the Apache web server
function fn_remove_package_apache_web() {
    echo "Uninstalling Apache web server..." &&
    systemctl stop httpd && # Stop the service
    systemctl disable httpd && # Disable the service
    yum remove -y httpd && # Uninstall the Apache web server package
    echo "Uninstalled Apache web server!"
}

function fn_configure_package_nginx() {
    # Port variables
    standard_http_port=80
    standard_https_port=443
    nginx_http_port=8080
    nginx_https_port=8443
    # NGINX default configuration variables
    nginxDefaultConfigFile=nginx.conf
    nginxDefaultConfigFileDest=/etc/nginx/
    # Update default config file for nginx
    mv -f $nginxDefaultConfigFile $nginxDefaultConfigFileDest &&
    # Path variables for static nginx sites
    nginxStaticSitesAvailableDir=/var/nginx-static/sites-available/
    nginxStaticSitesEnabledDir=/var/nginx-static/sites-enabled/
    # Create directories for static nginx sites
    mkdir $nginxStaticSitesAvailableDir &&
    mkdir $nginxStaticSitesEnabledDir &&

    # Create nginx configuration file for jonathanlee.io static page
    nginxJonathanLeeIoStaticConfigFile=jonathanlee.io.conf
    nginxJonathanLeeIoStaticConfigFileDest=/etc/nginx/conf.d/
    # Update config file
    mv -f $nginxJonathanLeeIoStaticConfigFile $nginxJonathanLeeIoStaticConfigFileDest &&

    # Clone and enable static jonathanlee.io site
    git clone https://github.com/jonathan-lee-devel/jonathanlee.io.git $nginxStaticSitesAvailableDir/ &&
    # Create symlink to enable jonathanlee.io site
    # TODO

    # Change permissions for necessary nginx files to be used by nginx running as nginx user
    # TODO

    # Configure firewall to forward standard HTTP and HTTPS traffic to NGINX
    iptables -t nat -A PREROUTING -p tcp --dport $standard_http_port -j REDIRECT --to-port $nginx_http_port &&
    iptables -t nat -A PREROUTING -p tcp --dport $standard_https_port -j REDIRECT --to-port $nginx_https_port &&
    iptables-save > /etc/iptables.conf &&
    #-------------------------------------------------------------------------------------TODO#####################################
    echo "DEBUG: Check if firewall rerouting to NGINX is permanent!!!"
    # TODO
    #Add the following command in /etc/rc.local to reload the rules in every reboot.
    #
    #$  iptables-restore < /etc/iptables.conf

    # Create nginx service file to run as nginx user on boot
    # NGINX service file variables
    nginxServiceFile=nginx.service
    nginxServiceFileDest=/etc/systemd/multi-user.target.wants/
    # Update nginx service file
    mv -f $nginxServiceFile $nginxServiceFileDest &&
    # Reload systemctl
    systemctl daemon-reload &&
    # Reload nginx configuration
    nginx -s reload &&
    # Start nginx
    systemctl start nginx &&
    systemctl enable nginx &&
    #-------------------------------------------------------------------------------------TODO#####################################
    echo "DEBUG: Check if nginx master process is running as root!!!"
}

function fn_configure_package_pm2() {
    # Create pm2 configuration for node user
    # TODO Create file and change permissions
    pm2ConfigurationFileDest=/var/node/pm2/
    # Update PM2 configuration file
    mv -f ecosystem.config.js $pm2ConfigurationFileDest
}

# Update yum and install all of the necessary packages
function fn_install_all_packages() {
    echo "Beginning installation of required packages..." &&
    echo "Updating yum..." &&
    yum update -y && # Update yum
    echo "Yum updated!" &&
    fn_install_pacakge_wandisco_git && # Install git
    fn_install_package_nginx && # Install NGINX
    fn_install_package_nodejs && # Install Node.js
    fn_install_package_pm2 && # Install PM2
    echo "Installed packages!"
}

# Stop & uninstall all unnecessary packages
function fn_remove_all_packages() {
    echo "Beginning uninstallation of unnecessary packages..." &&
    fn_remove_package_apache_web &&
    echo "Uninstalled unnecessary packages!"
}

# Configure all of the packages
function fn_configure_all_packages() {
    fn_configure_package_nginx &&
    fn_configure_package_pm2
}

# Clean up leftover files used by the script
function fn_clean_up() {
    echo "Cleaning up leftover files..." &&
    rm *.repo *.service *.js *.conf && #  Remove leftover files
    echo "Cleaned up leftover files!"
}

# Ensure that the script is being run as root, otherwise exit
function fn_root_check() {
    if [ "$EUID" -ne 0 ] # Check if root
    then
        echo "Intialization script must be run as root, Exiting!" &&
        exit
    fi
}

# Ensure that all files exist
function fn_file_check() {

}

# Ensure that all pre-checks pass
function fn_pre_check_all() {
    fn_root_check
    fn_file_check
}

# Calls all necessary functions in required order
function fn_main() {
    echo "Running initalization script..." &&
    fn_pre_check_all && # Check script running as root
    fn_install_all_packages && # Install required packages
    fn_remove_all_packages && # Uninstall unnecessary packages
    fn_configure_all_packages &&
    fn_clean_up && # Remove leftover files
    echo "Ran initialization script!"
}

fn_main # Calls all of the necessary functions