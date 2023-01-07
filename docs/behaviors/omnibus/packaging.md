# Packaging 

Omnibus projects have the ability to produce a platform package from the build artifacts it's tasks.

[Barista::Behaviors::Omnibus::Project#packager][] returns a platform specific packager for the host OS.

[Barista::Behaviors::Omnibus::Project#package][] will package an distributable package using the project metadata and the task artifacts.

!!! note 

    An Omnibus project will autodetect the packager for the host, or raise an error if it cannot find one.

!!! warning

    The current supported packagers are `Barista::Behaviors::Omnibus::Packagers::Deb` and `Barista::Behaviors::Omnibus::Packagers::Rpm`

    Supported platforms are `debian, ubuntu, centos, redhat, and fedora`
