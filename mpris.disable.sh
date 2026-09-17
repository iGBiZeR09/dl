systemctl --user stop mpris-proxy.service
systemctl --user disable mpris-proxy.service
systemctl --user mask mpris-proxy.service

sudo systemctl --global disable mpris-proxy.service
