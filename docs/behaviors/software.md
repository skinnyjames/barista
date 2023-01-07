# Barista::Behaviors::Software

These mixins are for building or interacting with the operating system or software via commands.

## Barista::Behaviors::Software::Project

Software projects 

* have the ability to bundle files into the generated binary
* can do lookups about the host OS, available memory, and the host architecture

!!! info

    As a rule of thumb, when using `Barista::Behaviors::Software::Task`, it should [belong to](/barista/getting_started/#baristabelongsto) a `Barista::Behaviors::Software::Project` to ensure proper type resolution.

## Barista::Behaviors::Software::Task

Software tasks

* can run commands and emit their output
* process templates 
* patch, sync or link files
* execute arbitrary Crystal code.
* can bundle files into the generated binary
* can do lookups about the host OS, available memory, and the host architecture

### Building

Software tasks have a different interface than a [Barista::Task][].

While the latter uses `#execute`, Software tasks use `#build`.

This is because Software tasks save all commands as state.  
Internally [Barista::Behaviors::Software::Task#execute][] will call `#build` first to save the commands on the Task object.

This is useful for implementing caches or digests on Tasks, and is used in `Barista::Behaviors::Omnibus::Task`.

### Extra tools

the `Barista::Behaviors::Software` module also contains some extra tooling.

* [Barista::Behaviors::Software::Merger][] can sync a source directory to a destination directory, and can reconstruct symbolic links.
* [Barista::Behaviors::Software::SizeCalculator][] can concurrently calcuate the size of a given list of directories (useful for large directories)
* [Barista::Behaviors::Software::Fetchers::Net][] can fetch a compressed software archive from the internet, verify its digest, and unpack it into a directory

