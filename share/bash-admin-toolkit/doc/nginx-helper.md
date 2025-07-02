# 🧩 `bat-nginx-helper.sh` — NGINX Site Management Helper

## Overview

This script manages NGINX virtual hosts via CLI options or external configuration files.  
It is designed to be reusable both in interactive use and in scripted automation (e.g., postinstall triggers).

---

## 📌 Features

- Create or remove a virtual host
- Auto-generate an SSL certificate (self-signed)
- Add entries to `/etc/hosts`
- Manage default webroot, logs, and firewall rules
- Compatible with `.conf`, `.args`, `.env` trigger formats

---

## 🚀 Usage

```bash
./bat-nginx-helper.sh [options]
```

### Examples

Create a new HTTPS site:

```bash
./bat-nginx-helper.sh -v mysite -p 443
```

Remove a site and its data:

```bash
./bat-nginx-helper.sh -r data -v mysite
```

Use external config file:

```bash
./bat-nginx-helper.sh -c ./postinstall.d/20-nginx.conf
```

---

## 🧩 Options

| Short | Long          | Description                             |
| ----- | ------------- | --------------------------------------- |
| `-v`  | `--vhost`     | Virtual host name (required)            |
| `-p`  | `--port`      | Listening port (e.g. 80 or 443)         |
| `-D`  | `--domain`    | Domain suffix (default: `local`)        |
| `-s`  | `--ssl`       | SSL mode: `autosign`, `none`, etc.      |
| `-r`  | `--remove`    | Remove mode (config : config only, data : all)    |
| `-o`  | `--overwrite` | Overwrite existing site (default: 0)    |
| `-c`  | `--conf`      | Use config file for options             |
| `-d`  | `--debug`     | Enable debug mode (not yet implemented) |
| `-h`  | `--help`      | Show help and exit                      |

> ℹ️ All options can be provided via command-line or loaded from a `.conf` file.

---

## ⚙️ Configuration File Support

A `.conf` file is a Bash script that defines variables like:

```bash
VHOST="myapp"
DOMAIN="local"
LISTEN_PORT="443"
REMOVE_MODE="data"
```

It is sourced with the `-c` flag:

```bash
bat-nginx-helper.sh -c 20-nginx.conf
```

---

## 📁 Generated Resources

* Webroot: `/var/www/<vhost>/html`
* Logs: `/var/www/<vhost>/logs`
* NGINX site file: `/etc/nginx/sites-available/<vhost>`
* Hosts entry: `/etc/hosts`
* SSL cert (self-signed): `/etc/ssl/<vhost>.crt / key`

---

## 🔐 Security Integration

If HTTPS (`443`) is detected:

* A self-signed certificate is generated (via `autosign_certificate`)
* The site is added and activated
* Firewall rules are appended (via `append_firewall_rules`)

---

## 🔄 Remove Mode (`-r` / `--remove`)

| Value | Description                  |
| ----- | ---------------------------- |
| `1`   | Remove config only           |
| `2`   | Remove config, data, and SSL |

---

## ⚠️ Requirements

* Bash ≥ 4.0
* `nginx`, `openssl`, `sed`, `grep`
* Helpers rely on:

  * `common.lib.bash`
  * `keycert.lib.bash`
  * `nginx.lib.bash`

> 🔍 These libraries must be located at `$PREFIX/lib/bash-admin-toolkit`.

---

## 📘 Notes

* The script exits on first error (`set -e`)
* Automatically installs NGINX if missing
* All output is minimal by design, but could be enhanced with debug modes later

---

## ✅ Exit codes

| Code | Meaning                  |
| ---- | ------------------------ |
| `0`  | Success                  |
| `1`+ | Failure or invalid input |

---

## 🛠️ Maintainer

Developed and maintained by [HervéP530](https://github.com/hervep530)
Feel free to suggest improvements or report issues.
