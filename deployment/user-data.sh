#!/bin/bash
# Launch prepends SOURCE_COMMIT with the exact reviewed Git commit.
set -euo pipefail
: "${SOURCE_COMMIT:?Set the exact Git commit to deploy}"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y nginx python3-venv curl ca-certificates unattended-upgrades
install -d -o www-data -g www-data /opt/t2-hello-world
curl --fail --location --retry 5 \
  "https://github.com/premiumstoic/csci4830-t2-hello-world/archive/${SOURCE_COMMIT}.tar.gz" \
  -o /tmp/t2-source.tar.gz
tar -xzf /tmp/t2-source.tar.gz --strip-components=1 -C /opt/t2-hello-world
python3 -m venv /opt/t2-hello-world/.venv
/opt/t2-hello-world/.venv/bin/pip install -r /opt/t2-hello-world/requirements.txt
python3 - <<'PY'
from pathlib import Path
import secrets
Path('/etc/t2-hello-world.env').write_text(
    'DJANGO_SECRET_KEY=' + secrets.token_urlsafe(64) + '\n'
    'DJANGO_DEBUG=false\n'
)
PY
chown root:www-data /etc/t2-hello-world.env
chmod 640 /etc/t2-hello-world.env
# Refresh allowed hosts at each boot, because an auto-assigned IP can change.
cat > /usr/local/bin/t2-refresh-hosts <<'SCRIPT'
#!/bin/bash
set -euo pipefail
token=$(curl --fail --silent --show-error --retry 5 --connect-timeout 5 \
  -X PUT -H 'X-aws-ec2-metadata-token-ttl-seconds: 60' \
  http://169.254.169.254/latest/api/token)
ip=$(curl --fail --silent --show-error --retry 5 --connect-timeout 5 \
  -H "X-aws-ec2-metadata-token: $token" \
  http://169.254.169.254/latest/meta-data/public-ipv4)
dns=$(curl --fail --silent --show-error --retry 5 --connect-timeout 5 \
  -H "X-aws-ec2-metadata-token: $token" \
  http://169.254.169.254/latest/meta-data/public-hostname)
sed -i '/^DJANGO_ALLOWED_HOSTS=/d' /etc/t2-hello-world.env
printf 'DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1,%s,%s\n' "$ip" "$dns" >> /etc/t2-hello-world.env
SCRIPT
chmod 750 /usr/local/bin/t2-refresh-hosts
/usr/local/bin/t2-refresh-hosts
set -a
source /etc/t2-hello-world.env
set +a
cd /opt/t2-hello-world
.venv/bin/python manage.py check
.venv/bin/python manage.py migrate --noinput
chown -R www-data:www-data /opt/t2-hello-world
cat > /etc/systemd/system/t2-hello-world.service <<'SERVICE'
[Unit]
Description=CSCI 4830 T2 Django Hello World
After=network-online.target
Wants=network-online.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/opt/t2-hello-world
EnvironmentFile=/etc/t2-hello-world.env
ExecStartPre=+/usr/local/bin/t2-refresh-hosts
ExecStart=/opt/t2-hello-world/.venv/bin/gunicorn --workers 1 --bind 127.0.0.1:8000 --access-logfile - --error-logfile - config.wsgi:application
Restart=on-failure
RestartSec=5
PrivateTmp=true
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
SERVICE
cat > /etc/nginx/sites-available/t2-hello-world <<'NGINX'
server {
    listen 80 default_server;
    server_name _;
    server_tokens off;
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX
rm -f /etc/nginx/sites-enabled/default
ln -sfn /etc/nginx/sites-available/t2-hello-world /etc/nginx/sites-enabled/t2-hello-world
nginx -t
systemctl daemon-reload
systemctl enable --now t2-hello-world.service
systemctl enable nginx
systemctl restart nginx
curl --fail --retry 5 --retry-connrefused http://127.0.0.1/
printf '%s\n' "$SOURCE_COMMIT" > /opt/t2-hello-world/DEPLOYED_COMMIT
