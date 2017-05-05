# slack_emoji_import
A few Ruby / Selenium scripts I wrote to manage importing custom Slack emoji

## Scripts

### import.rb
 
The main attraction. Reads files in `images/` and compares filenames to the
list of existing emoji, uploading those that are missing.

I had started with a version that copied directly, however:

1. I wanted to edit the list before importing
1. Our work Slack uses 2-factor auth, which made logging in with the script annoying.

### fetch_list.rb

Passed a file full of URLs, downloads them in parallel to `images/`

### editor.rb

_Super_ simple Sinatra app for moving images from `images/` to `images/removed/` 
where they will not be imported by `import.rb`
