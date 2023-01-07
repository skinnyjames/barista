# Developing

Development of Barista requires a couple of dependencies.

* [Crystal](https://crystal-lang.org/install/)
* [Python](https://www.python.org/downloads/) (for docs)

After installing the dependencies

* `git clone https://gitlab.com/skinnyjames/barista && cd barista`
* `shards install` to install project dependencies
* `crystal spec` to run the specs

## Considerations

The library structure encapsulates behaviors in their own directories

```
/src
  /barista # for base level features
    /behaviors
      /omnibus # for omnibus features
      /software # for general software features
```

!!! info

    Since Barista is class/interface based, it is easy to expose new behaviors by including modules into a Project/Task

    If a feature seems specific to the usage of Barista rather than the interface of it's Behaviors, consider keeping it in the consuming library.

## Spec considerations

The Barista specs provide helpers for integration testing the e2e flow.
This includes

* An HTTP server to publish and fetch cached artifacts and source archives.
* Fixture paths for configuring Omnibus projects safely
* Predefined cache callbacks to use when testing Omnibus projects
* Ability to intercept output from an Orchestrated run

## Documentation

The documentation is generated with [mkdocs](https://www.mkdocs.org/).  It requires python, and installs a virtual env in the project.

* To watch/serve the docs, run `make serve`.
* To buid the docs, run `make build`