#!/bin/bash
# pan_autossl_setup.sh will request a certificate and create a cron job to automatically renew the certificate and push it to the PAN

# Request API Key and save to .panrc
echo -n "Management IP: "
read pan_mgmt_ip
echo -n "API User for PAN: "
read api_user
echo -n "Password:"
read -s api_password

echo "Requesting API Key..."    
api_key=$(panxapi.py -h $pan_mgmt_ip -l $api_user:$api_password -k | awk '{print $3}'| sed 's/"//g')

echo "hostname=$pan_mgmt_ip" > ~/.panrc
echo "api_key=$api_key" >> ~/.panrc

# Generate config file for auto renew script, create directory, and move script into location
echo -n "FQDN for certificate: "
read ssl_fqdn
echo -n "Email address for Certbot: "
read email
echo -n "Name of Certificate within the PAN: "
read cert_name
echo -n "Name of GP Portal TLS Profile: "
read gp_portal_tls_profile
echo -n "Name of GP Gateway TLS Profile: "
read gp_gw_tls_profile
echo -n "Request certificate now? (y/n)": 
read req_cert
if test ! -d ~/pan_autossl
then
  mkdir ~/pan_autossl
fi

declare -p ssl_fqdn email cert_name gp_portal_tls_profile gp_gw_tls_profile api_key pan_mgmt_ip > ~/pan_autossl/conf
cp pan_autossl_renew.sh ~/pan_autossl/

# Request certificate, upload to PAN, and configure GP Gateway and Portal TLS Profiles
if [ $req_cert = 'y' ]
then
  sudo certbot --nginx -d $ssl_fqdn -m $email -n --agree-tos
fi

if test `sudo find -L "/etc/letsencrypt/live/$ssl_fqdn/cert.pem" -mmin -5`
then
  pushd ~/pan_autossl
  echo "Converting certificate into PFX and uploading to PAN..."
  TEMP_PWD=$(openssl rand -hex 15)
  sudo openssl pkcs12 -export -out letsencrypt_pkcs12.pfx -inkey /etc/letsencrypt/live/$ssl_fqdn/privkey.pem -in /etc/letsencrypt/live/$ssl_fqdn/cert.pem -certfile /etc/letsencrypt/live/$ssl_fqdn/chain.pem -passout pass:$TEMP_PWD
  sudo curl -k --form file=@letsencrypt_pkcs12.pfx "https://$pan_mgmt_ip/api/?type=import&category=certificate&certificate-name=$cert_name& format=pkcs12&passphrase=$TEMP_PWD&key=$api_key" && echo " "
  sudo curl -k --form file=@letsencrypt_pkcs12.pfx "https://$pan_mgmt_ip/api/?type=import&category=private-key&certificate-name=$cert_name& format=pkcs12&passphrase=$TEMP_PWD&key=$api_key" && echo " "
  sudo rm letsencrypt_pkcs12.pfx -f
  panxapi.py -S "<certificate>$cert_name</certificate>" "/config/shared/ssl-tls-service-profile/entry[@name='$gp_portal_tls_profile']"
  panxapi.py -S "<certificate>$cert_name</certificate>" "/config/shared/ssl-tls-service-profile/entry[@name='$gp_gw_tls_profile']"
  echo "Comitting PAN changes..."
  panxapi.py -C '' --sync
  popd
fi
#Create auto renewal job if it doesn't already exist
echo "Creating renewal task if it doesn't exist..."
if ! crontab -l|grep pan_autossl_renew
then
  crontab -l | { cat; echo "11 */12 * * * ~/pan_autossl/pan_autossl_renew.sh"; } | crontab -
fi
echo "Finished."