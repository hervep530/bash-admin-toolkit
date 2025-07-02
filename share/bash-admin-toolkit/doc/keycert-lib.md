# Documentation for `keycert.lib.bash`

### Description

This library contains functions to manage SSL certificates and SSH keys, including generating self-signed certificates, removing certificates, and importing SSH public keys for users.

---

### Main Functions

#### `autosign_certificate <vhost> <domain> <duration>`

Generates a self-signed SSL certificate and private key valid for `<duration>` days.

* Key saved at `/etc/ssl/private/${vhost}.key`
* Certificate saved at `/etc/ssl/certs/${vhost}.crt`
* The certificate uses the subject common name `CN=${vhost}.${domain}`.

---

#### `remove_certificate <vhost>`

Removes the private key and certificate files associated with `<vhost>`.

* Checks if the private key exists before attempting removal.

---

#### `import_ssh_key <username> <ssh_pubkey>`

Imports the SSH public key into the user’s `~/.ssh/authorized_keys`.

* Creates `.ssh` directory if it does not exist.
* Sets appropriate permissions (700 for `.ssh`, 600 for `authorized_keys`).
* Assigns ownership to the user and their primary group.

---
