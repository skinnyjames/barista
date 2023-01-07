# Barista::Behaviors::Omnibus::Project

The entry point to writing a full-stack installer with Barista is the [Barista::Behaviors::Omnibus::Project][] module.

When including into a [Barista::Project][], it provides methods to

* add information about the package (metadata, versioning, build location)
* write a summary of aggregated licenses
* package the artifacts using the platforms packaging method
