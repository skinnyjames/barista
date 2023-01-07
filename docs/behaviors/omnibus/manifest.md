# Manifest

A project can return manifest of it's non virtual tasks. 

This is mostly done for compatibility with the Omnibus project.

To return a manifest for a project, see [Barista::Behaviors::Omnibus::Project#manifest][]

!!! note

    The manifest can return json via `Omnibus::Manifest#to_json` or `Omnibus::Manifest#to_pretty_json`
