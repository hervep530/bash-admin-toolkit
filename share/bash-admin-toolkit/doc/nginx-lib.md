# nginx.lib.bash

**Description:**
This library contains functions to install, configure, enable, and remove Nginx virtual hosts, as well as manage firewall rules related to the configured ports.

---

## Variables

| Variable          | Description                                           |
| ----------------- | ----------------------------------------------------- |
| `NGINX_CONF_DIR`  | Path to Nginx configuration directory (`/etc/nginx`)  |
| `SITES_AVAILABLE` | Path to available sites directory (`sites-available`) |
| `SITES_ENABLED`   | Path to enabled sites directory (`sites-enabled`)     |

---

## Functions

### `site_exists()`

Check if the Nginx site configuration file exists.

* **Returns:**
  `1` if site config exists, otherwise `0`.

---

### `create_site()`

Create directories and Nginx configuration file for a new virtual host.

* Creates web root and logs directories.
* Generates a basic `index.html` test page if missing.
* Writes the Nginx server block configuration:

  * If listening on HTTP (port 80), sets a non-SSL server block.
  * If listening on HTTPS port, sets SSL server block with certificate paths.

**Uses environment variables:**

* `VHOST` - Virtual host name
* `DOMAIN` - Domain suffix (default: `local`)
* `LISTEN_PORT` - Port number to listen on
* `WEBROOT` - Web root directory (e.g., `/var/www/$VHOST/html`)
* `LOGDIR` - Log directory (e.g., `/var/www/$VHOST/logs`)
* `NGINX_CONF` - Path to site config file

---

### `get_nginx_listen_port()`

Retrieve the listen port from the Nginx site config.

* If the config file exists, extracts the port number from `listen` directive.
* Otherwise returns default port `80`.

---

### `remove_site()`

Remove the Nginx virtual host:

* Deletes site config and symlink from enabled sites.
* Restarts Nginx service.
* If `REMOVE_MODE` is set to `data`, removes webroot and logs directories.

---

### `activate_site()`

Activate the Nginx site:

* Creates a symlink from sites-available to sites-enabled if not present.
* Tests Nginx configuration syntax (`nginx -t`).
* Restarts Nginx service.
* Enables Nginx service at system boot (`update-rc.d nginx defaults`).

---

### `append_firewall_rules()`

Add iptables firewall rules to allow TCP traffic on `LISTEN_PORT`.

* Adds INPUT and OUTPUT rules if not already present.
* Saves rules persistently using `netfilter-persistent save`.

---

### `nginx_postinstall_help()`

Display usage help message. (Currently a placeholder to be implemented.)

---

## Notes

* Requires bash shell.
* Nginx must be installed and manageable via `service` command.
* Assumes Debian-style filesystem paths and `iptables` firewall.
* The functions rely on environment variables being set externally (e.g., by the helper script).

---

