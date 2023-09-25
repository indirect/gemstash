---
title: gemstash-authorize
date: October 9, 2015
section: 1
...

# Name

gemstash-authorize - Adds or removes authorization to interact with privately stored gems

# Synopsis

`gemstash authorize [permissions] [--remove] [--list] [--key SECURE_KEY] [--name NAME] [--config-file FILE]`

# Description

Adds or removes authorization to interact with privately stored gems.

Any arguments will be used as specific permissions. Valid permissions include
`push`, `yank`, and `fetch`. If no permissions are provided, then all
permissions will be granted (including any that may be added in future versions
of Gemstash).

## Usage
```
gemstash authorize
gemstash authorize push yank
gemstash authorize push --name my-auth
gemstash authorize yank --key <secure-key>
gemstash authorize --remove --key <secure-key>
gemstash authorize --list
```

# Options

* `--config-file FILE`:
    Specify the config file to use. If you aren't using the default config file
    at `~/.gemstash/config.yml` or [`~/.gemstash/config.yml.erb`][ERB_CONFIG],
    then you must specify the config file via this option.

* `--key SECURE_KEY`:
    Specify the API key to affect. This should be the actual key value, not a name.
    This option is required when using `--remove` but is optional otherwise. If
    adding an authorization, using this will either create or update the permissions
    for the specified API key. If missing, a new API key will always be generated.
    Note that a key can only have a maximum length of 255 chars.

* `--name`:
    Name of the authorization. Purely for ease of identification, not required.

* `--remove`:
    Remove an authorization rather than add or update one. When removing, permission
    values are not allowed. The `--key <secure-key>` option is required.

* `--list`:
    List current authorizations. Provide `--name` or `--key` to show only one result.

[ERB_CONFIG]: ./gemstash-customize.7.md#erb-parsed-config
