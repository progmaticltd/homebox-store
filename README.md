This repository contains the code to deploy the minimal store used for backup tests in
[Homebox](https://github.com/progmaticltd/homebox). However, you can use this code to deploy a backup server online for
your homebox, with the SSH backend.

It is actually used with [vultr](https://vultr.com/), so you can have a cheap online backup storage.

## System settings

- Security updates are automatically installed by default.
- The firewall (ufw) configured to restrict both input and output traffic.
- Only one backup user is created, and borg-backup is installed.
- Only SSH connections are authorised, restricted to borg-backup except for root.

## Sharing backup with mutliple users

Albeit it is not as safe as having one server per user, you can share the storage with many users. The setup is using
the "account" concept:

- Each account has a unique ID (UUID), and the public SSH key associated to the account can be changed.
- When the SSH connection is established with the associated key, only borg-backup can run.
- The SSH connection is restricted in the same folder as the UUID.

For instance, consider this configuration in your system.yml file:

```yaml
backup:
  username: userbackups
  keys_list:
    - uuid: 895ca4fa-8b63-11e9-8609-3ba52727fc8d
      expire: '2020-12-31'
      email: sabrina.duncan@angels.com
      comment: Sabrina's laptop
      type: ecdsa-sha2-nistp384
      data: >-
        AAAAE2VjZHNhXkoPYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBPlBOzIxp+6MgozPqL
        iSUgkpa5J08EmuyWhsIJskh34SDUUVEZtfU23FhQyI8SzFWcBKkHgbz0nsLgUtsxvTwXt8
        adkiVRTKCBUF4uCNSZzah5h5U+m4MJumCRRCJQXxaQ==
      state: present
    - uuid: a21c1e7a-8b64-11e9-bf10-5f5b81ecdc4a
      expire: '2020-12-31'
      email: jill.munroe@angels.com
      comment: Jill's workstation
      type: ssh-rsa
      data: >-
        AAAAB3NzaC1yc2EAAAADAQABAAABAQCtj/2Qcmgdo2XHKUXrJ5wAeZKCeHeoP5FDPniaf1
        jdZI3JwKNJGnJaWwxCp00QVJi6PmhkmBz5rAWgs+ZE1YUXIa3pFXYm/PLEiUMkh0SrX9O3
        QBgXMSqkw1mymz34wWTUROkJ4/UtsXyvoe3eiQ/y8W9fJ/5SXzfTmmbC/WVe9qEVag6Bz2
        CXsYDUQ5YOntm+eIc1S/HuSiKayf/PNrSenUQ6MQfxzI70+MVq9ZCPyA8KJ+ruQUUDCoPT
        J64oha7HMJue8EPZawIbWLNmKEP2kspdpTsrPJ7f6XJ0hoorcDnqxXR7Ebk3WmLT0a59J/
        FgWzrij2bC5ty80CtI3iP5
      state: present
    - uuid: 63b50ae0-8b71-11e9-b705-637aee29bba2
      expire: '2019-12-31'
      email: kelly.garrett@angels.com
      comment: Kelly's workstation
      type: ssh-rsa
      data: >-
        AAAAB3NzaC1yc2EAAAADAQABAAABAQDAI2A/kqtr0lB+oqtKDj4f5WW6UL/xQyjl9sl8JV
        o1ZcTMS0vZ61yPl8OYvsR4A7a+rSKoc7X3gdIQdhdUC+uB0K9doLVmofUv//SK0rOE50Cj
        VKnHMMhqmxt+zz/WdiyXKOqQ4heqS31rqwNzlaCRgp5R7dnwVCl4v6MrVujBWUJVYdQBUP
        c/q3+B7S8xmtgsJgb/b33z466+PWQ1JaAsMtz8up7I9W7b6KYrMKAbt0u8pA+wARZllmnP
        t2c9GtmoGYYWH5+wmHEjuXaHEnQ5Nz9AG4MS8WNgZJfek+S2hsSBm13t3M+9qxoOK3rIDM
        pMc76ZZVV9G8fCufQaOA3f
      state: absent
```

Once deployed using Ansible, the ssh authorized_keys file will be built, with this content:

```text
# 895ca4fa-8b63-11e9-8609-3ba52727fc8d:sabrina.duncan@angels.com:1640908800:present
command="borg serve --restrict-to-path /home/userbackups/895ca4fa-8b63-11e9-8609-3ba52727fc8d",restrict ecdsa-sha2-nistp384 AAAAE2[…]QXxaQ== Sabrina's laptop
# a21c1e7a-8b64-11e9-bf10-5f5b81ecdc4a:sabrina.duncan@angels.com:1609372800:present
command="borg serve --restrict-to-path /home/userbackups/a21c1e7a-8b64-11e9-bf10-5f5b81ecdc4a",restrict ssh-rsa AAAAB3[…]bC5ty80CtI3iP5 Jill's workstation
# 63b50ae0-8b71-11e9-b705-637aee29bba2:kelly.garrett@angels.com:1609372800:absent
```

## Adding or removing user accounts

The Ansible script is idempotent, you can run it multiple times. It will simply update the authorized_keys file
accordingly.

## Daily update script

Every night, a simple bash script is run, to disable the keys that have expired. At this time, no warning is sent to the
user prior the key deactivation. Once a key is expired, the authorized_keys looks like this:

```text
# 895ca4fa-8b63-11e9-8609-3ba52727fc8d:sabrina.duncan@angels.com:1640908800:present
command="borg serve --restrict-to-path /home/userbackups/895ca4fa-8b63-11e9-8609-3ba52727fc8d",restrict ecdsa-sha2-nistp384 AAAAE2[…]QXxaQ== Sabrina's laptop
# a21c1e7a-8b64-11e9-bf10-5f5b81ecdc4a:sabrina.duncan@angels.com:1609372800:expired
# command="borg serve --restrict-to-path /home/userbackups/a21c1e7a-8b64-11e9-bf10-5f5b81ecdc4a",restrict ssh-rsa AAAAB3[…]bC5ty80CtI3iP5 Jill's workstation
# 63b50ae0-8b71-11e9-b705-637aee29bba2:kelly.garrett@angels.com:1609372800:absent
```
