# mcal

Less than 500 lines of suckless code for managing the macOS built-in calendar
app from command line. So you don't have to align the events with your fucking
pointer pixel by pixel (I hate it).

### who is `mcal` for?
This program meant for people who record everything minute by minute to their
calendar, that is, editing only previous/current/next events in the near time.
Neither scheduling future events nor editing past events cannot be done with
`mcal`.

## install
Takes couple of seconds to compile.
```
swiftc main.swift -o /usr/local/bin/mcal
```
or if you want to make things easier and complicated at the same time then
```
brew tap 0ihsan/packages
brew install mcal
```

## features
* [ ] Ignore subscribed (remote) calendars since user can't change those.
* [X] Display the information of the current event. (`mcal now`)
* [X] Adjust the current event end date to the current time (finish). (`mcal end`)
* [X] Create new events on existing calendars. (`mcal personal 30 spend time with family`)
* [X] Add location data (`mcal personal 15 drink coffee at everest`)
* [X] Bring future (next) event to current time (`mcal next`)
* [X] Continue previous event (`mcal continue`) (ends the current and
      copies previous event to current time)
* [X] Push last forgotten event as started from the last event and ends now.
      (`mcal push ...`)

## usage
`mcal` or `mcal -h` or `mcal --help` or `mcal help`

![usage](https://i.imgur.com/WtWvmaz.png)

You may want to disable OS logs with this environment variable:
```sh
export OS_ACTIVITY_DT_MODE=NO
export OS_ACTIVITY_MODE=disable
```

## license
MIT

## notes for developers
The code is not that clean but not long as well. I might not accept your pull
request if you send bloated changes. Feel free to fork and use however you
want.

## notes for myself
### update brew package

- commit your changes here
   - don't forget to increase the version number
- create a tag with `git tag v1.1.8` for example.
- push the changes with `git push && git push origin v1.1.8` for example.
- `brew edit mcal` sync the version number to the newest.
- `brew upgrade mcal`, get the sha256 and put it in the mcal.rb file
- commit the changes and push them.
