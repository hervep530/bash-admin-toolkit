# Documentation for `common.lib.bash`

### Description

This library provides shared utility functions commonly used in installation scripts. It includes option parsing, service installation and management, iptables rules handling, hosts file modifications, and debug logging utilities.

---

### Main Functions

#### `install_service <service_name>`

Checks if a service is installed; if not, updates package lists and installs it via `apt`.

---

#### `get_options <args...>`

Parses command-line options in the form of `-key` or `--key` with optional values, storing them in associative arrays for later use.

---

#### `add_iptables_rule <chain> <rule>`

Adds an iptables rule to a given chain if it doesn’t already exist.

---

#### `save_iptables`

Saves the current iptables rules persistently using `netfilter-persistent`.

---

#### `start_service <service_name>`

Restarts a service and enables it at system startup (SysVinit).

---

#### `hosts_add <hostname> <reference_line>`

Adds an entry for `hostname` to the hosts file `/etc/hosts`, inserting it after the line matching `reference_line` if present.

---

#### `hosts_remove <hostname>`

Removes any hosts file entries matching `hostname`.

---

#### `log_step <message>`

Simple logging function to mark a step or stage in the output.

---

#### `log_debug <level> <message...>`

Outputs debug messages depending on the global debug level set in `DEBUG_LEVEL`.

---

#### `set_debug_level`

Sets the global debug level based on parsed options (e.g., `debug=1`).

---
