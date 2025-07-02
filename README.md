# 🛠️ Bash Admin Toolkit

A modular Bash-based framework for automating system installation, configuration, and administration tasks.  
Initially designed for **Devuan (SysVInit)** server post-installation, it is structured to support broader use cases, including workstation setup and embedded systems configuration.

---

## 🎯 Goals

- Centralize personal admin scripts into a maintainable and reusable toolkit.
- Provide a **modular architecture** for:
  - One-shot post-install automation
  - Reusable CLI helpers for common system tasks
  - A function library for clean, DRY scripting
- Ensure clarity, reusability, and separation of concerns.

---

## 🧱 Architecture Overview

The toolkit is organized into **three logical layers**:

### 1. Post-install Application (`opt/bash-admin-toolkit`)
- `launcher.sh`: Entry point for running post-install tasks.
- `postinstall.d/`: Ordered triggers and configurations for installation logic.

> 💡 This layer can be used either for one-time execution after system installation or for targeted operations during system lifecycle.

### 2. CLI Helpers (`sbin/`)
Standalone command-line tools for managing subsystems:
- Examples: `bat-nginx-helper.sh`, `bat-ssh-helper.sh`, `bat-user-helper.sh`, etc.
- Accept configuration from `.conf`, `.args`, or `.env` files.
- Can be reused independently of the postinstall logic.

### 3. Function Libraries (`lib/bash-admin-toolkit/`)
Reusable Bash function sets:
- `common.lib.bash`: General-purpose utilities (logging, checks, etc.)
- `nginx.lib.bash`, `keycert.lib.bash`, etc.
- Used by the CLI helpers and other scripts to reduce code duplication.

---

## ⚙️ Postinstall Trigger System

The `postinstall.d/` directory contains ordered scripts and configuration files that act as **execution triggers**.

### Supported file types:

| Type | Description |
|------|-------------|
| `NN-name.sh`   | Executable Bash script (self-contained logic) |
| `NN-name.conf` | Sourced Bash file: defines variables for **a single helper execution** |
| `NN-name.args` | Each line runs the helper once, passing **CLI arguments** |
| `NN-name.env`  | Each line sets an environment and runs the helper accordingly |

> Files are executed in numeric order (e.g. `10-ssh.sh`, `20-nginx.conf`, etc.).

---

## 📁 Project Structure


```
.
├── lib/bash-admin-toolkit/
│   ├── common.lib.bash
│   ├── keycert.lib.bash
│   ├── nginx.lib.bash
│   └── package.lib.bash
├── opt/bash-admin-toolkit/
│   ├── launcher.sh
│   └── postinstall.d/
│       ├── 00-refactoring.sh
│       ├── 10-ssh.sh
│       ├── 20-nginx.conf
│       ├── 21-nginx.conf
│       ├── 22-nginx.args
│       ├── 23-nginx.args
│       ├── 24-nginx.env
│       └── 25-nginx.env
├── sbin/
│   ├── bat-network-helper.sh
│   ├── bat-nginx-helper.sh
│   ├── bat-package-helper.sh
│   ├── bat-ssh-helper.sh
│   └── bat-user-helper.sh
├── share/bash-admin-toolkit/doc/
│   ├── common-lib.md
│   ├── nginx-helper.md
│   ├── nginx-lib.md
│   └── index.md
└── README.md
```

---

## 🚀 Examples

### 1. Run full postinstall routine
```bash
sudo /opt/bash-admin-toolkit/launcher.sh
````

### 2. Run a CLI helper directly

```bash
sudo bat-nginx-helper.sh -v myvhost -D local -p 443
```

---

## 🔧 Dependencies

This toolkit depends on Bash and common GNU/Linux tools.
Some helpers require additional components such as:

* `nginx`, `sshd`, `openssl`
* `gpg`, `curl`, `apt`, `getent`, etc.

> Dependency checks are performed by each helper when needed.

---

## 📦 Packaging & Deployment

Designed to support:

* Local install via `make install` (not included yet)
* Future `.deb`, `.rpm`, or `.tar.gz` packaging
* Lightweight usage via Git clone (no install required)

---

## 🔮 Planned Features

* Additional helpers for `gitea`, `podman`, `firewall`, etc.
* Support for embedded systems, video encoding, WM config
* Auto-generated documentation from libraries and scripts

---

## 📚 Documentation

See [`share/bash-admin-toolkit/doc/`](share/bash-admin-toolkit/doc/) for:

* CLI helper documentation
* Library references
* Postinstall usage patterns

---

## 👤 Author

Maintained by [HervéP530](https://github.com/hervep530) — feedback and contributions welcome.

## License

Distributed under license **Apache 2.0**.
Voir [LICENSE](./LICENSE) pour plus de détails.
