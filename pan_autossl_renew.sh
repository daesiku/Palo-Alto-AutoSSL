#!/bin/bash
# pan_autossl_renew.sh will auto renew the certificate and push it to PAN
pushd ~/pan_autossl
. ./conf
sudo certbot renew --nginx
if test `sudo find -L "/etc/letsencrypt/live/$ssl_fqdn/cert.pem" -mmin -5`
then
  TEMP_PWD=$(openssl rand -hex 15)
  echo "Cert renewed. Pushing to PAN..."
  TEMP_PWD=$(openssl rand -hex 15)
  sudo openssl pkcs12 -export -out letsencrypt_pkcs12.pfx -inkey /etc/letsencrypt/live/$ssl_fqdn/privkey.pem -in /etc/letsencrypt/live/$ssl_fqdn/cert.pem -certfile /etc/letsencrypt/live/$ssl_fqdn/chain.pem -passout pass:$TEMP_PWD
  sudo curl -k --form file=@letsencrypt_pkcs12.pfx "https://$pan_mgmt_ip/api/?type=import&category=certificate&certificate-name=$cert_name&format=pkcs12&passphrase=$TEMP_PWD&key=$api_key" && echo " "
  sudo curl -k --form file=@letsencrypt_pkcs12.pfx "https://$pan_mgmt_ip/api/?type=import&category=private-key&certificate-name=$cert_name&format=pkcs12&passphrase=$TEMP_PWD&key=$api_key" && echo " "
  sudo rm letsencrypt_pkcs12.pfx
  echo -n "Comitting changes."
  panxapi.py -C '' --sync & 
  while kill -0 $!; do
    printf '.' > /dev/tty
    sleep 2
  done
  printf '\n' > /dev/tty
fi

popd