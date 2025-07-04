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

#### Create a new HTTPS site

```bash
./bat-nginx-helper.sh -v mysite -D mydomain -p 443
```

#### Remove a site and its data

```bash
./bat-nginx-helper.sh -d 1 -q 0 -r data -v mysite
```

#### Use external config file

```bash
./bat-nginx-helper.sh -c ./postinstall.d/20-nginx.conf
```
#### Use environment variables

```bash
DEBUG_LEVEL=2 QUIET=0 ./bat-nginx-helper.sh -v mywebsite -D mydomain -p 80
DEBUG_LEVEL=1 QUIET=0 ./bat-nginx-helper.sh -c ./postinstall.d/20-nginx.conf
```
💡 *Last example is more relevant. It shows how to use DEBUGLEVEL and QUIET, when keeping default value in conf file, in case of tests. This command change comportment, without affecting settings in file.*

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
| `-d`  | `--debug`     | Enable debug mode [0|1|2] (default : 0) |
| `-q`  | `--quiet`     | Doesn't display verbose system command message (default 1)|
| `-f`  | `--force`     | Force script to continue even if a component failed (default : 0) |
| `-i`  | `--safe-interactive` | If not force, prompt user to stop or continue (default : 0) |
| `-h`  | `--help`      | Show help and exit                      |

> ℹ️ All options can be provided via command-line or loaded from a `.conf` file.

---

## ⚙️ Helper Configuration File Support

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

## ⚙️ Other environment variables 

you will find below other environment variables and matching CLI options :

|  env           | CLI options   | Values   | Description                             |
| -------------- | ------------- | -------- | --------------------------------------- |
| *VHOST*        | `--vhost`     | <vhost>  | Virtual host name (required)            |
| *LISTEN_PORT*  | `--port`      | <port>   | Listening port (e.g. 80 or 443)         |
| *DOMAIN*       | `--domain`    | <domain> | Domain suffix (default: `local`)        |
| *SSL*          | `--ssl`       | [autosign Letsenc]  | SSL mode: `autosign`, `none`, etc.      |
| *REMOVE_MODE*  | `--remove`    | [config data]  | Remove mode (config : config only, data : all)    |
| *OVERWRITE*    | `--overwrite` | [0 1]    | Overwrite existing site (default: 0)    |
|                | `--conf`      | <path>   | Use config file for options             |
| **DEBUG_LEVEL** | `--debug`     | [0 1 2]  | Enable debug mode [0|1|2] (default : 0) |
| **QUIET**       | `--quiet`     | [0 1]    | Doesn't display verbose system command message (default 1)|
| **FORCE**       | `--force`     | [0 1]    | Force script to continue even if a component failed (default : 0) |
| **SAFE_INTERACTIVE** | `--safe-interactive` | [0 1]  | If not force, prompt user to stop or continue (default : 0) |
|                | `--help`      | [0 1]    | Show help and exit                      |


It will be used alternatively with launcher (why not helper), to modify a default comportment, without changing source code.
In italic, variables are dedicated to helper, and will vary. In bold, variable are generic and should be implemented for all helpers. The common library provides utility to manage it without difficulty.

```bash
sudo /bin/bash -c "PREFIX=/usr/local TRIGGER_DIR=/etc/myfirewall.d /opt/bash-admin-toolkit/launcher.sh"
DEBUG_LEVEL=2 bat-nginx-helper.sh -c 10-nginx.conf
```
> ℹ️ *Remark : use of sudo is depending of helper actions. With bat-nginx-helper, it's necessary, because of services and system management (/etc/hosts,...). But keep in mind that it would be not recommended for all tasks (video or graphic tools for example)*

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

## 🔄 Options codification
  
### Remove Mode (`-r` / `--remove`/ `REMOVE_MODE`)

|  Value   | Description                  |
| -------- | ---------------------------- |
| `config` | Remove config only           |
| `data`   | Remove config, data, and SSL |

---

### Message - Debug level ( `-d` / `--debug` / `DEBUG_LEVEL`)

|  Value   | Description                  |
| -------- | ---------------------------- |
| `0`      | Off                          |
| `1   `   | Debug                        |
| `2   `   | Verbose                        |

---

### Message - Quiet ( `-q` / `--quiet` / `QUIET`)

|  Value   | Description                                |
| -------- | ------------------------------------------ |
| `0`      | Displays command stdout and stderr        |
| `1   `   | Doesn't display command  stderr (TODO : route to a log file|

---

### Handle error - Force ( `-f` / `--force` / `FORCE`)

|  Value   | Description                                |
| -------- | ------------------------------------------ |
| `0`      | Exit or manage error interactivly          |
| `1   `   | Continue after error                       |

---

### Handle error - Safe interactive ( `-i` / `--safe-interactive` / `SAFE_INTERACTIVE`)

|  Value   | Description                                       |
| -------- | ------------------------------------------------- |
| `0`      | Exit without prompting                            |
| `1`      | Prompt to continue or not when exit code is not 0 |

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

* The script offer flexibility with handling error. When returns status not 0, you have options to stop all, continue anyway, or prompt user
* Automatically installs NGINX if missing
* All output is minimal by design, but could be enhanced with debug modes

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
