# mcal
A simple script for managing macOS built-in calendar app from command line. So you don't have to align the events with your mouse.

### who is `mcal` for?
This program meant for people who record everything minute by minute to their calendar. `mcal` deals only with previous/current/next event in the near time. Scheduling future events or editing past events cannot be done with `mcal`.

## install
```
swiftc mcal.swift -o /usr/local/bin/mcal
```
or
```
brew tap 0ihsan/packages
brew install mcal
```

## features
* [X] Show current event. (`mcal show`)
* [X] List today's events. (`mcal list`)
* [X] Finish current event. (`mcal end`)
* [X] Create new event with duration, title and/or location on existing calendars. (`mcal personal 30 spend time with family at home`)
* [X] Bring future event to current time (`mcal next`)
* [X] Continue previous event (`mcal con`) (ends the current and copies previous event to current time)
* [X] Push a forgotten event as started from the last event's end. (`mcal push [ ... ]`)
* [ ] Ignore subscribed (remote) calendars since user can't change those.

## usage
`mcal help`

![usage](https://imgur.com/a/lzMGtHN)

You can disable OS logs:
```sh
export OS_ACTIVITY_DT_MODE=NO
export OS_ACTIVITY_MODE=disable
```

## notes for developers
Feel free to fork and do whatever you want but notice I might not accept your pull request.

## notes for myself
### update brew package

- commit your changes here
 - adjust version number
- create a tag with `git tag v1.1.8` for example.
- `git push && git push origin v1.1.8`
- brew tap and `brew edit mcal` sync the version number to the newest.
- `brew upgrade mcal`, get the sha256 and put it in the mcal.rb file
- commit the changes on 0ihsan/packages and push.
