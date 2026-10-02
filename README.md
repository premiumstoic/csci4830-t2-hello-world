# CSCI 4830 — T2 Hello World

A fresh Django app for the Tech Exercise setup checkpoint. The `/` route displays
**Hello, world!**. The EC2 website URL will be added after deployment is verified.

## Run locally

```sh
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
python manage.py migrate
python manage.py check
python manage.py runserver
```

Open http://127.0.0.1:8000/.

## Request flow

`config/urls.py` includes `hello_world/urls.py`, which maps `/` to
`hello_world/views.py:index`. The view returns a small HTML response.

## Server configuration

Ubuntu 24.04, Nginx, Gunicorn, and systemd. Gunicorn listens on localhost only;
Nginx accepts public HTTP requests on port 80. Systemd starts the app after boot
and restarts it if it exits. No login or personal data is collected by this demo.

Production settings require `DJANGO_SECRET_KEY`, `DJANGO_DEBUG=false`, and an
explicit `DJANGO_ALLOWED_HOSTS` list. The bootstrap script generates the secret
on the server; no real secret or AWS credential belongs in this repository.

EC2 access uses Systems Manager with `AmazonSSMManagedInstanceCore`, without an
SSH key or inbound SSH port. The deployment script is `deployment/user-data.sh`.
Its source download is pinned to the reviewed Git commit before launch.

## Cost and lifecycle

The deployment uses one t3.micro in us-east-2, standard CPU credits, encrypted
8 GiB gp3 storage, and an auto-assigned public IPv4 address. Compute, storage,
public IPv4, and any billable traffic incur charges on a paid AWS plan. Stopping
the server takes the website offline and changes its public IP on restart;
storage charges continue while stopped. Keep it online while it is being graded,
then clean up resources when no longer needed.
