---
layout: post
title: Interactive R scripts
date: '2015-05-08 20:24:37'
---

R is a great tool for writing small programs that compute statistics or visualize data, and could potentially replace the wide usage hacked-together bash, perl or python scripts that output gnuplot commands. In particular, the [ggplot2](http://ggplot2.org/) library makes creating beautiful (and complex) plots extremely simple. However, one problem in particular is preventing this vision from becoming reality: R does not support [interactive scripting](https://stat.ethz.ch/pipermail/r-help/2010-July/245619.html).

With R, you have two options for how to run applications. You either run `R` to launch the R interactive REPL, or you write a `.R` script that you then run with `Rscript`.  In the former mode, you can draw plots, call `readLines` to ask the user for input, and in general interact with the user and the screen. In "batch" mode, however, R does not let you do any of these things. `readLines` will always return immediately with no input, and any window you display will be immediately closed when the application terminates. There are various hacks you can use to work around this, such as specifically doing `readLines(file("stdin"))`, or you could insert a call to `Sys.sleep` after showing a plot, but these aren't always perfect. For example, making the application sleep after showing a plot means the plot isn't interactive, so resizing the window will not cause a re-draw, and you're left with a blank window.

Since R does not (currently) provide a way for scripts to force interactive mode (like octave's `--persist` flag), we need a better fix. Luckily, it turns out that there is a loophole in R that lets us imitate this feature. When R first starts up, it checks the environment variable `R_PROFILE_USER`, and if it is non-empty, it executes that script **before dropping to interactive mode**. We can use this to provide an interactive R script executor in `/usr/local/bin/Rint`:
```
#!/bin/sh
f=$1; shift; env "R_PROFILE_USER=$f" "ARGS=$@" R --no-save -q
```

You can now change your R plotting scripts to include the line
```
#!/usr/local/bin/Rint
```
at the top of the file, and `./plot.R` will work exactly as if you typed the commands in R yourself!

Note that this script is executed before many of the default libraries are included, so you might want to start your scripts with including common libraries:
```
#!/usr/local/bin/Rint
library(grDevices)
library(utils)
```