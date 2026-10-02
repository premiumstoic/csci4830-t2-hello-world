# CSCI 4830 T2 deployment

Launched October 1, 2026 at 10:38 p.m. America/Chicago. Bootstrap finished in
about one minute. Public HTTP verification passed at approximately 10:39 p.m.

- Website: http://18.117.233.67/
- Alternate hostname: http://ec2-18-117-233-67.us-east-2.compute.amazonaws.com/
- Repository: https://github.com/premiumstoic/csci4830-t2-hello-world
- Deployed source commit: `fe1d7b5e25ffc8babb480ad65ed735a319365e82`
- Instance: `i-07849ae77bdd32b81`, named `csci4830-t2-hello-world`
- Region / Availability Zone: `us-east-2` / `us-east-2a`
- Type: `t3.micro`, 2 vCPUs, 1 GiB RAM, burstable CPU in standard credit mode
- Image: Canonical Ubuntu 24.04 x86_64, `ami-0fa99aa8f97f9e30b`
- VPC: `vpc-09a8ba5754a9d592b`; public subnet: `subnet-0486babe39e448ea3`
- Private IPv4: `172.31.8.37`; auto-assigned public IPv4: `18.117.233.67`
- Security group: `sg-01d9e5f9a2df52b85`
- Disk: `vol-0c5ae9786fa967657`, encrypted 8 GiB gp3, 3,000 IOPS, 125 MiB/s;
  root disk is deleted on termination.
- Basic monitoring; detailed monitoring and termination protection disabled.
- Tags identify Owner `premiumstoic`, Project/CostCenter `CSCI4830`, Environment
  `development`, WorkloadType `web-server`, ManagedBy `Codex`, CreatedDate
  `2026-10-01`, and the instance name. Instance, disk, role, profile, and security
  group carry these tags.

## Access and security

Public inbound access is TCP 80 only. No SSH key was created and port 22 is
closed. Outbound access permits internet package downloads and Systems Manager.
Instance metadata requires IMDSv2 with a hop limit of 1.

Role/profile `csci4830-t2-hello-world-ssm` grants the server only
`AmazonSSMManagedInstanceCore`, with an EC2 service trust policy. Systems Manager
reports the server online. Open the instance in the EC2 console and choose
Connect → Session Manager for administrative access.

Nginx proxies requests to Gunicorn on `127.0.0.1:8000`. The app runs as
`www-data`, with debug disabled, explicit allowed hosts, and a server-generated
secret stored in `/etc/t2-hello-world.env` (root-owned, group-readable only).
The bootstrap downloads a pinned Git commit. Systemd enables both services at
boot, restarts the app on failure, and refreshes allowed hosts if the public IP
changes. Unattended security updates are installed.

This is an HTTP-only Hello World demonstration. Add a domain and TLS before
introducing authentication or collecting private information.

## Verification

- Cloud-init completed with no errors.
- Nginx configuration validation passed.
- Django checks and database migrations passed on EC2.
- Nginx and the app systemd service are active.
- Public HTTP request returns 200 with the expected Hello World response.
- The server's deployed commit file matches the source commit above.
- AWS APIs confirm the encrypted disk, requested network, HTTP-only ingress,
  standard credits, IMDSv2 requirement, tags, and instance profile.
- EC2 system, instance, and attached EBS health checks all passed. The instance
  profile association is confirmed as `associated`.

## Cost

AWS reports an active paid plan and zero remaining promotional credits.
Verified Ohio pricing: compute $0.0104/hour, gp3 $0.08/GB-month; public IPv4
$0.005/hour. At 730 running hours: compute $7.592, IPv4 $3.65, storage $0.64,
total about **$11.88**, before taxes and billable traffic. About **$0.39/day**.
Standard credits avoid unlimited-mode surplus CPU charges but can limit CPU
performance after credits are depleted. Basic monitoring has no detailed-metric
charge. No load balancer, NAT gateway, Elastic IP, or extra disk was created.

## Operation and cleanup

Keep the instance running while the assignment is graded. Stopping it takes
the website offline, releases its auto-assigned public IP, and stops compute
charges; EBS storage continues to incur charges. On start, check the new public
IP and update any submitted links. Terminating deletes this server and its root
disk. The source remains on GitHub. Afterwards, remove the assignment security
group, detach the role policy, remove the role from its instance profile, and
delete the profile and role when no longer needed.

Within a Session Manager shell, check the app with:

```sh
sudo systemctl status t2-hello-world nginx
sudo journalctl -u t2-hello-world -n 50
sudo tail -n 50 /var/log/cloud-init-output.log
curl --fail http://127.0.0.1/
```

For an unreachable page, check the instance state, public IP, EC2 health checks,
security group, and then Nginx/app logs. If bootstrap failed, inspect cloud-init
output. Do not print or commit the secret environment file.

For future expansion, consider status-check/CPU alarms, application log
forwarding, a backup strategy for persistent data, and billing alerts. The
current app contains no user data, and its source can recreate the deployment.
