# 🧩 Launcher Script — `launcher.sh`

## Overview

The `launcher.sh` script is the core entry point to run administrative routines after a system installation or system reset.

It parses and executes a set of structured "trigger" files, which can be:
- Executable scripts (`.sh`)
- Configuration files (`.conf`)
- Argument lists (`.args`)
- Environment variable sets (`.env`)

The launcher automatically determines the execution mode based on the file type.

---

## Location

Expected location:  
`/opt/bash-admin-toolkit/launcher.sh`

Triggers directory:  
- Default: `./launcher.d/` (replaced with `.d/` based on script name)
- Overridable via env var: `TRIGGER_TYPE=postinstall` → `./postinstall.d/`

Execution acces is needed for triggers you want to activated. You can do it following this example :
```
sudo chmod +x ./launcher.d/20-nginx.conf
```

---

## Trigger Types

| Extension | Description |
|----------|-------------|
| `.sh`     | Executable Bash scripts — run directly. |
| `.conf`   | Config file sourced by the matching helper with `-c` option. |
| `.args`   | Each line is a CLI argument set passed to the helper. |
| `.env`    | Each line defines environment variables passed to the helper. |

---

## Helper Detection

For each trigger file, the launcher:
1. Extracts the base name from the filename (e.g., `20-nginx.args` → `nginx`)
2. Builds the helper path: `/usr/sbin/bat-nginx-helper.sh` (or overridden via `$PREFIX`)
3. Executes the helper accordingly.

---

## Execution Logic

Each trigger file is processed as follows:

### `.sh` – Standalone Scripts

```bash
/bin/bash $TRIGGER_DIR/NN-name.sh
````

### `.conf` – Configuration Mode

```bash
bat-<name>-helper.sh -c $TRIGGER_DIR/NN-name.conf
```

### `.args` – CLI Arguments Mode

Each line must match a predefined CLI pattern. Example:

```
--vhost myweb --domain mydomain --port 443
```

The launcher calls:

```bash
bat-<name>-helper.sh <parsed CLI line>
```

### `.env` – Environment Variable Mode

Each line defines ENV variables (e.g.):

```
VHOST=mysite DOMAIN=mydomain LISTEN_PORT=80
```

Then calls:

```bash
/bin/bash -c "VHOST=mysite DOMAIN=mydomain LISTEN_PORT=80 bat-<name>-helper.sh"
```

---

## Environment Variables

| Variable       | Description                                       |
| -------------- | ------------------------------------------------- |
| `PREFIX`       | Override installation prefix (default: `/usr`)    |
| `TRIGGER_TYPE` | Use alternate trigger set (e.g., `postinstall.d`) |

---

## Dependencies

* Bash >= 4.0
* Core Unix tools: `sed`, `grep`, `ls`
* Helpers in `PREFIX/sbin/`

---

## Example Usage

### Full post-install execution

```bash
sudo /opt/bash-admin-toolkit/launcher.sh
```

### Use alternate prefix and trigger type

```bash
sudo bash -c "PREFIX=$(pwd) TRIGGER_TYPE=postinstall ./opt/bash-admin-toolkit/launcher.sh"
```

---

## Exit Behavior

The launcher does not stop on first error — it continues processing all triggers.

---

## Future Improvements (TODO)

* Add logging / error summary
* Optional dry-run mode
* Better validation of `.args` and `.env` lines

````

---
