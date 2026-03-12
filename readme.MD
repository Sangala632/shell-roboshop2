# Roboshop 3 Tier Architecture

![Architecture Diagram](roboshop-infra-dev.drawio.svg)
# RoboShop – Shell Provisioning Scripts

RoboShop is a multi-tier e-commerce demo application. This repository contains **Bash scripts that automate the installation and configuration of every service** on RHEL / Rocky Linux 9 servers. Each script mirrors what you would do manually, making it easy to follow and extend.

---

## Architecture Overview

```
                        ┌─────────────┐
                        │   Browser   │
                        └──────┬──────┘
                               │ :80
                        ┌──────▼──────┐
                        │  Frontend   │  Nginx 1.24  (static SPA + reverse proxy)
                        └──────┬──────┘
           ┌───────────────────┼──────────────────────┐
           │                   │                      │
    ┌──────▼──────┐    ┌───────▼──────┐    ┌──────────▼────────┐
    │  Catalogue  │    │     User     │    │       Cart        │
    │  Node.js 20 │    │  Node.js 20  │    │   Node.js 20      │
    └──────┬──────┘    └──────┬───────┘    └──────────┬────────┘
           │                  │                       │
    ┌──────▼──────┐    ┌──────▼───────┐    ┌──────────▼────────┐
    │   MongoDB   │    │  MongoDB +   │    │  Redis + Catalogue │
    │             │    │    Redis     │    │                   │
    └─────────────┘    └──────────────┘    └───────────────────┘
                                                      │
                                            ┌─────────▼─────────┐
                                            │     Shipping      │
                                            │  Java (Spring)    │
                                            └─────────┬─────────┘
                                                      │
                                            ┌─────────▼─────────┐
                                            │      Payment      │
                                            │  Python / uWSGI   │
                                            └─────────┬─────────┘
                                                      │
                                            ┌─────────▼─────────┐
                                            │     RabbitMQ      │
                                            └───────────────────┘
```

| Tier | Service | Technology | Port |
|------|---------|------------|------|
| Presentation | Frontend | Nginx 1.24 | 80 |
| Application | Catalogue | Node.js 20 | 8080 |
| Application | User | Node.js 20 | 8080 |
| Application | Cart | Node.js 20 | 8080 |
| Application | Shipping | Java 17 / Maven | 8080 |
| Application | Payment | Python 3 / uWSGI | 8080 |
| Data | MongoDB | v7.0 | 27017 |
| Data | Redis | v7 | 6379 |
| Data | MySQL | v8 | 3306 |
| Messaging | RabbitMQ | v3.x | 5672 |

---

## Prerequisites

- **OS:** RHEL 9 / Rocky Linux 9 / AlmaLinux 9
- **Access:** Root or `sudo` on every server
- **DNS:** A wildcard or per-service DNS record pointing each hostname to its server (see [DNS Configuration](#dns-configuration))
- **Network:** All servers must be able to reach each other on the ports listed above
- **Internet:** Servers need outbound HTTPS to download packages and application artifacts from S3

---

## Repository Structure

```
shell-roboshop/
├── common.sh          # Shared helper functions (used by all app scripts)
├── roboshop.sh        # AWS automation – provision EC2 instances + Route 53 records
│
├── mongodb.sh         # Install & configure MongoDB 7
├── redis.sh           # Install & configure Redis 7
├── mysql.sh           # Install & configure MySQL 8
├── rabbitmq.sh        # Install & configure RabbitMQ
│
├── catalogue.sh       # Deploy Catalogue service (Node.js)
├── user.sh            # Deploy User service (Node.js)
├── cart.sh            # Deploy Cart service (Node.js)
├── shipping.sh        # Deploy Shipping service (Java/Maven)
├── payment.sh         # Deploy Payment service (Python/uWSGI)
├── frontend.sh        # Deploy Frontend (Nginx + static bundle)
│
├── catalogue.service  # systemd unit – Catalogue
├── user.service       # systemd unit – User
├── cart.service       # systemd unit – Cart
├── shipping.service   # systemd unit – Shipping
├── payment.service    # systemd unit – Payment
│
├── nginx.conf         # Custom Nginx config with API proxy rules
├── mongodb.repo       # Yum repo definition for MongoDB 7
└── rabbitmq.repo      # Yum repo definitions for RabbitMQ + Erlang
```

---

## DNS Configuration

Every service is identified by a hostname. Update the values in `roboshop.sh` to match your domain, or create the records manually before running the scripts.

| Hostname | Points to |
|----------|-----------|
| `mongodb.<domain>` | MongoDB server |
| `redis.<domain>` | Redis server |
| `mysql.<domain>` | MySQL server |
| `rabbitmq.<domain>` | RabbitMQ server |
| `catalogue.<domain>` | Catalogue server |
| `user.<domain>` | User server |
| `cart.<domain>` | Cart server |
| `shipping.<domain>` | Shipping server |
| `payment.<domain>` | Payment server |
| `<domain>` | Frontend server (public IP) |

> **Tip:** If you are using AWS Route 53, run `roboshop.sh` to provision EC2 instances and DNS records automatically (see [AWS Automation](#aws-automation)).

---

## Installation Order

Services must be installed in dependency order. Follow the steps below — each command must be run **on the designated server** as `root`.

### Step 1 — Data & Messaging tier

```bash
# MongoDB
bash mongodb.sh

# Redis
bash redis.sh

# MySQL  (you will be prompted for the root password)
bash mysql.sh

# RabbitMQ  (you will be prompted for the roboshop user password)
bash rabbitmq.sh
```

### Step 2 — Application tier

```bash
# Catalogue  (depends on MongoDB)
bash catalogue.sh

# User  (depends on MongoDB + Redis)
bash user.sh

# Cart  (depends on Redis + Catalogue)
bash cart.sh

# Shipping  (depends on MySQL + Cart)
#   You will be prompted for the MySQL root password
bash shipping.sh

# Payment  (depends on Cart + User + RabbitMQ)
bash payment.sh
```

### Step 3 — Presentation tier

```bash
# Frontend  (depends on all application services)
bash frontend.sh
```

---

## Script Reference

### `common.sh`

Sourced by every application script. Provides:

| Function | Description |
|----------|-------------|
| `check_root` | Exits if the script is not run as root |
| `app_setup` | Creates the `roboshop` system user, downloads and unzips the application artifact from S3 into `/app` |
| `nodejs_setup` | Enables the Node.js 20 module, installs it, and runs `npm install` |
| `maven_setup` | Installs Maven + Java, runs `mvn clean package`, and renames the output jar |
| `python_setup` | Installs Python 3, `pip install -r requirements.txt`, copies the systemd unit |
| `systemd_setup` | Copies the service unit file, reloads systemd, enables and starts the service |
| `VALIDATE` | Prints `SUCCESS` or `FAILURE` for the last command and exits on failure |
| `print_time` | Prints total script execution time |

### Individual scripts

| Script | What it does |
|--------|-------------|
| `mongodb.sh` | Installs MongoDB 7 from the custom repo, starts `mongod`, and opens it to all interfaces (`0.0.0.0`) |
| `redis.sh` | Enables Redis 7 module, installs it, disables protected-mode, and binds to all interfaces |
| `mysql.sh` | Installs MySQL 8, runs `mysql_secure_installation` with the provided root password |
| `rabbitmq.sh` | Installs RabbitMQ from the custom repo, creates the `roboshop` user, and grants full permissions on `/` |
| `catalogue.sh` | Deploys the Node.js catalogue service; loads the MongoDB master schema on first run |
| `user.sh` | Deploys the Node.js user service |
| `cart.sh` | Deploys the Node.js cart service |
| `shipping.sh` | Deploys the Java shipping service; loads the MySQL schema and master data on first run |
| `payment.sh` | Deploys the Python payment service via uWSGI |
| `frontend.sh` | Deploys the static frontend bundle and configures Nginx as a reverse proxy to all backend services |

---

## Environment Variables (systemd units)

Each service is configured through environment variables in its `.service` file.

**Catalogue** (`catalogue.service`)
| Variable | Default | Description |
|----------|---------|-------------|
| `MONGO` | `true` | Enable MongoDB mode |
| `MONGO_URL` | `mongodb://mongodb.<domain>:27017/catalogue` | MongoDB connection string |

**User** (`user.service`)
| Variable | Default | Description |
|----------|---------|-------------|
| `MONGO` | `true` | Enable MongoDB mode |
| `MONGO_URL` | `mongodb://mongodb.<domain>:27017/users` | MongoDB connection string |
| `REDIS_URL` | `redis://redis.<domain>:6379` | Redis connection string |

**Cart** (`cart.service`)
| Variable | Default | Description |
|----------|---------|-------------|
| `REDIS_HOST` | `redis.<domain>` | Redis hostname |
| `CATALOGUE_HOST` | `catalogue.<domain>` | Catalogue service hostname |
| `CATALOGUE_PORT` | `8080` | Catalogue service port |

**Shipping** (`shipping.service`)
| Variable | Default | Description |
|----------|---------|-------------|
| `CART_ENDPOINT` | `cart.<domain>:8080` | Cart service endpoint |
| `DB_HOST` | `mysql.<domain>` | MySQL hostname |

**Payment** (`payment.service`)
| Variable | Default | Description |
|----------|---------|-------------|
| `CART_HOST` | `cart.<domain>` | Cart service hostname |
| `CART_PORT` | `8080` | Cart service port |
| `USER_HOST` | `user.<domain>` | User service hostname |
| `USER_PORT` | `8080` | User service port |
| `AMQP_HOST` | `rabbitmq.<domain>` | RabbitMQ hostname |
| `AMQP_USER` | `roboshop` | RabbitMQ username |
| `AMQP_PASS` | `roboshop123` | RabbitMQ password |

---

## Logs

All scripts write detailed logs to `/var/log/roboshop-logs/`.

```bash
# View logs for a specific service script
tail -f /var/log/roboshop-logs/catalogue.log

# View systemd service logs at runtime
journalctl -u catalogue -f
```

---

## AWS Automation

`roboshop.sh` provisions the full infrastructure on AWS automatically.

**Before running**, update these variables at the top of the file:

```bash
AMI_ID="ami-09c813fb71547fc4f"     # RHEL 9 AMI for your region
SG_ID="sg-xxxxxxxxxxxxxxxxx"        # Security group allowing service ports
ZONE_ID="ZXXXXXXXXXXXXXXXXXXXXX"    # Route 53 hosted zone ID
DOMAIN_NAME="yourdomain.com"        # Your domain
```

**Usage:**

```bash
# Provision all services
bash roboshop.sh mongodb redis mysql rabbitmq catalogue user cart shipping payment frontend

# Provision a subset
bash roboshop.sh catalogue user cart
```

The script creates `t3.micro` EC2 instances, tags them with the service name, and upserts the corresponding Route 53 DNS records (private IP for frontend, public IPs for all other services).

---

## Troubleshooting

**Service fails to start**
```bash
systemctl status <service-name>
journalctl -u <service-name> --no-pager -n 50
```

**Re-run a script after a failure**

Each script is idempotent for the system-user and directory creation steps. Simply re-run it:
```bash
bash catalogue.sh
```

**MongoDB schema not loading**

The `catalogue.sh` script checks whether the `catalogue` database exists before loading data. To force a reload:
```bash
mongosh --host mongodb.<domain> --eval 'db.getSiblingDB("catalogue").dropDatabase()'
bash catalogue.sh
```

**MySQL schema not loading**

The `shipping.sh` script checks for the `cities` database before loading. To force a reload:
```bash
mysql -h mysql.<domain> -uroot -p -e 'DROP DATABASE cities;'
bash shipping.sh
```

---

## Security Notes

- Change the default RabbitMQ password (`roboshop123`) in `rabbitmq.sh` and `payment.service` before deploying to production.
- Change the MySQL root password when prompted during `mysql.sh`.
- Restrict the security group to allow inter-service traffic only between known server IPs.
- The `mongod` and `redis` configurations bind to `0.0.0.0` — ensure firewall rules limit access to application servers only.