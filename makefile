prefix ?= /usr/local
bin = $(prefix)/bin

mcal:
	swiftc main.swift -o mcal

install: mcal
	install -d "$(bin)"
	install mcal "$(bin)"

uninstall:
	rm -rf "$(bin)/mcal"

clean:
	rm -rf mcal

.PHONY: mcal install uninstall clean
