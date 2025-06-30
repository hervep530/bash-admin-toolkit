# bash-admin-toolkit : Unstable - development in progress

> Light library and script in bash to automatize some admin tasks

---

# 🛠️ Mon Projet Devuan Postinstall

This kit is providing script / library to make admin tasks easier.
It's optimized for a clean and fast deploiement, with possibility to enlarge features

it is also delivered with a first application : Devuan server postinstall

---

## 🚀 Aims

* Automatize additional installs and config
* Enforce security
* Prepare deployement base for dev / backend
* Simplify extents to other tools or services

---

### Postinstall actions on a devuan server

- Providing script ready to use
- Library to write new scripts
- A sample application to post-install devuan-server

---

## Prerequisite

For the moment, the code is written from a Devuan minimal install.
Bash, grep, sed are mainly used. Depending of needs, matching servers / services will be necessary.

---

## Structure

Folders **lib**, **sbin** and **share** and their subfolders **can become system components**. The structure already anticipate a makefile and install under a prefix.
Folder opt seems better place for our own cook. Let's take the example of devuan-server-postinstall :
- postinstall.sh will contains a routine to call all commands under postinstall.d
- other script will launch only one command (probably ssh case, except if you run more than one server). But for nginx, it will be interesting to isolate start command for all servers
These commands will be very easy to use and read. We will not implement any logic inside. The main logic is in helpers.
And finally to keep helpers as clean as possible, we use small library to isolate repetitive or complex code

```
.
├── opt
│   └── devuan-server-postinstall
│       ├── postinstall.d
│       │   ├── 10-ssh.sh
│       │   └── 20-nginx.sh
│       └── postinstall.sh
├── README.md
├── lib
│   └── bash-admin-toolkit
│       ├── common.lib.bash
│       ├── keycert.lib.bash
│       └── nginx.lib.bash
├── sbin
│   ├── bat-nginx-helper.sh
│   └── bat-ssh-helper.sh
└── share
    ├── bash-admin-toolkit
    │   └── doc
    └── man
        ├── man1
        └── man3
```

## License

Distributed under license **Apache 2.0**.
Voir [LICENSE](./LICENSE) pour plus de détails.
