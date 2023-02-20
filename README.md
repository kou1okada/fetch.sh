# fetch.sh

fetch URLs with cache.

## Usage

```
Usage: fetch [<URLs> ...]
  fetch URLs with cache.
  If set --ask-password option:
  1. $HTTPUSER and $HTTPPASS is used for wget, if they are set.
  2. Otherwise ask password from tty.
Options:
  -S, --server-response
      Show server response
  --ask-password
      Ask password
  -c, --cache-file
      Get cache file
  -f, --force
      Force update
  --no-ua-pretend
      No USER_AGENT	pretend
  -p, --progress
      Show progress
  -q, --quiet
      Quiet
  --status
      Show status
  --ua=<user_agent>
      Set USER_AGENT
  -u, --user=<user>
      Set http user
  --use-askpass=<askpass>
      Use askpass (default: getpw.bash)
```

## Requires

* [hhs.bash](https://github.com/kou1okada/hhs.bash)

## License

The MIT license.
