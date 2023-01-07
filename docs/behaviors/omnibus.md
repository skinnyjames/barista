# Omnibus

## Preface and acknowledgement

[Barista::Behaviors::Omnibus][] is heavily inspired by and aims to have similar compatibility with the wonderful work done by the Chef team

Please see: https://github.com/chef/omnibus

## About

In the same vein as chef/omnibus, this behavior provides functionality to build full-stack installers for distributable packages.

It provides mechanisms for building software sources concurrently, isolating and caching individual task artifacts, and bundling them together with licenses as a final package.

It extends the behavior and interface of [Barista::Behaviors::Software][]

!!! note

    Omnibus projects mutate the filesystem and are designed to be run inside of a docker container.