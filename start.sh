#!/bin/bash

# enable logging
set -x
exec > >(tee /var/log/user-data.log|logger -t user-data ) 2>&1

wget -O - https://repo.saltstack.com/py3/ubuntu/20.04/amd64/3001/SALTSTACK-GPG-KEY.pub | sudo apt-key add -
sudo deb http://repo.saltstack.com/py3/ubuntu/20.04/amd64/3001 focal main
sudo apt-get update
sudo apt-get install salt-master salt-minion

sudo rm /etc/salt/top.sls
sudo touch /etc/salt/top.sls
sudo chmod 0777 /etc/salt/top.sls
sudo cat > /etc/salt/top.sls <<-EOF
base:
  'G@os_family:Debian':
    - match: compound
    - apache-debian
EOF

sudo rm /etc/pillar/top.sls
sudo touch /etc/pillar/top.sls
sudo chmod 0777 /etc/pillar/top.sls
sudo cat > /etc/pillar/top.sls <<-EOF
base:
  '*':
    - apache
EOF

sudo rm /etc/pillar/apache.sls
sudo touch /etc/pillar/apache.sls
sudo chmod 0777 /etc/pillar/apache.sls
sudo cat > /etc/pillar/apache.sls <<-EOF
domain: example.com
EOF

sudo rm /etc/salt/example.com/index.html/
sudo touch /etc/salt/example.com/index.html
sudo chmod 0777 /etc/salt/example.com/index.html
sudo cat > /etc/salt/example.com/index.html <<-EOF
“{health: ok}”
EOF




sudo rm /etc/salt/apache.sls
sudo touch /etc/salt/apache.sls
sudo chmod 0777 /etc/salt/apache.sls
sudo cat > /etc/salt/apache.sls <<-EOF
apache2:
  pkg.installed

apache2 Service:
  service.running:
    - name: apache2
    - enable: True
    - require:
      - pkg: apache2

Turn Off KeepAlive:
  file.replace:
    - name: /etc/apache2/apache2.conf
    - pattern: 'KeepAlive On'
    - repl: 'KeepAlive Off'
    - show_changes: True
    - require:
      - pkg: apache2

 
000-default:
  apache_site.disabled:
    - require:
      - pkg: apache2

/etc/apache2/sites-available/{{ pillar['domain'] }}.conf:
  apache.configfile:
    - config:
      - VirtualHost:
          this: '*:80'
          ServerName:
            - {{ pillar['domain'] }}
          ServerAlias:
            - www.{{ pillar['domain'] }}
          DocumentRoot: /var/www/html/{{ pillar['domain'] }}/public_html
          ErrorLog: /var/www/html/{{ pillar['domain'] }}/log/error.log
          CustomLog: /var/www/html/{{ pillar['domain'] }}/log/access.log combined

{{ pillar['domain'] }}:
  apache_site.enabled:
    - require:
      - pkg: apache2

/var/www/html/{{ pillar['domain'] }}/public_html/index.html:
  file.managed:
    - source: salt://{{ pillar['domain'] }}/index.html
EOF

salt '*' state.apply

