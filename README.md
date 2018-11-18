# slack_emoji_import
A few Ruby / Selenium scripts I wrote to manage importing custom Slack emoji

Version 2.0 was brought about by Slack changing their upload UI. It completely
revamps how data is fetched, managed, and stored.

## Data and Caches

Rather than relying on the existence of files in a series of nested
directories, the scripts now cache the results of Slack API calls. This data
is considered canonical, and will only refresh once per day.

API data is cached in `data/raw/<name>.json`

## Configuration

The scripts all use libraries that read configuration from the
`config/credentials.yml` file. Each Slack Workspace you want to copy to/from
should be represented in hash of the following format:

```yaml
name:
  token: xoxp-Slack-Workspace-API-Token-Id-0123456789abcdef
  source: >
    boolean, optional value, true indicates this is the workspace from which
    you wish to copy by default.
  url: optional, defaults to name. The Slack url prefix to use when connecting
  username: the email address to use when logging in via the browser.
  password: the password to use when logging in via the browser. But see below.
  manual_login: >
    boolean, optional value, true indicates you want to manually run the login
    process on this Workspace, rather than driving it automatically.
    Particularly useful when your Workspace is managed by an SSO process that
    cannot be automated. This value obviates the need for  username and password.
```

### Passwords

Passwords can be stored in the `config/credentials.yml` file, however they can
also be read from the environment. Passwords are taken from the YAML, if
present, followed by the following environment variables, in order:

1. `SLACK_PASSWORD_<UPCASED_CONFIG_NAME>`
1. `SLACK_PASSWORD_<UPCASED_CONFIG_URL>` (when different)
1. `SLACK_PASSWORD`

If no password is found and `manual_login` is not set in the credentials file,
an error will be thrown.

## Scripts

### import.rb

The main attraction. The first argument is the destination to which to copy.
The second, optional, argument is the source from which to pull.

This script also reads the `data/disabled.yml` and `data/disabled.<dest>.yml`
and skips these items when copying data. (See [`editor.rb`](#editorrb) below.)

### editor.rb

A simple Sinatra app for building the `data/disabled.yml` file used by
`import.rb` above to skip files. Takes a destination and an optional source as
arguments, and has 2 endpoints:

* The root endpoint builds a table to allow you to define which items should be
  disabled everywhere, and which should be disabled only for this destination.
* <a name="diff_endpoint">The</a> `/diff` endpoint uses data from
  [`compare_images.rb`](#compare_imagesrb) to allow you to select the images on
  the destination that should be replaced by [`fix_images.rb`](#fix_imagesrb)
  below.

### compare_images.rb

Uses the cached images to build a list of emoji between a source and
destination where both Workspaces have a given emoji, yet it is not the same
file. Written to a file that can be used by `editor.rb` on the [`/diff`](#diff_endpoint)
endpoint, below.

### fix_images.rb

Uses data exported by the `/diff` endpoint of [`editor.rb`](#editorrb) above
to remove and re-upload images that need to be changed.
