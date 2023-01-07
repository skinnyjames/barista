# Logging

When building a lot of tasks at the same time, output can become quite chaotic.  We can mitigate this by subscribing to events and using provided tooling.

There is support for logging with [Barista::Log][].

This extends the default Crystal logger, but also takes:

* a caller to log where the log is coming from
* a color to differentiate the callers.

```crystal
Barista::Log.info("deep-freezer", color: :blue) { "Brr.. it's cold in here!" }
```

## Persistent Rich Logging

For persistent logging colorized output, we can use [Barista::RichLogger][]

```crystal
logger = Barista::RichLogger.new(name: "deep-freezer", color: :blue)

logger.info { "It sure is cold in here" }
logger.info { "..." }
logger.info { "Still cold!" }
```

## ColorIterator

Logging colorized output is nice, but it also becomes tedious to specify for persistent tasks.  

Barista provides a simple color iterator when it is important to tell the difference between tasks, but the hue doesn't matter.

This becomes helpful when using `Software` or `Omnibus` Behaviors.

```crystal
colors = Barista::ColorIterator.new

first_logger = Barista::RichLogger.new(name: "earth", colors.next)
second_logger = Barista::RichLogger.new(name: "moon", colors.next)
```
