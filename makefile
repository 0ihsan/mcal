prefix ?= /usr/local
bin = $(prefix)/bin
mcal:;swiftc mcal.swift
install:mcal;install -d "$(bin)";install mcal "$(bin)/mcal"
uninstall:;rm -rf "$(bin)/mcal"
