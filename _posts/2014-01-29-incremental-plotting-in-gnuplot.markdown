---
layout: post
title: Incremental plotting in gnuplot
date: '2014-01-29 18:04:03'
---

If you have ever had to plot something, chances are you've come across [gnuplot](http://www.gnuplot.info/). It's a very versatile plotting tool, and once you get used to the syntax and quirks, you quickly start using it from everything from throwaway data visualization to plots included in papers.

One use-case for gnuplot that there is currently no built-in support for, is handling incremental plotting where you have a data file that some other process is writing to, and you want your plot to update so that it always shows the latest data (or scale so it always shows all of it!). There are many ways of accomplishing this, most of which are based on having something like this in your plot file:

```gnuplot
load "< while [ 1 ]; do echo 'replot'; sleep .1s; done"
```

`load` is telling gnuplot to continue reading commands from the following source, and the `<` at the beginning of the source string tells it that it should execute what succeeds it as a shell command. Without asking questions, gnuplot does so, causing it to enter an infinte loop. Each time the script outputs `replot`, gnuplot goes ahead and replots, but since the input source isn't empty yet, it continues reading (blocking the application in the process). This certainly works, but it has the unfortunate side-effect of completely locking up the interface so you cannot interact with your data at all. Zooming and panning will simply not work. It is also somewhat inconvenient that script will never terminate, even when your data file is no longer being written to.

I therefore propose the following solution instead. First, you create a little bash script that generates your gnuplot script and puts it in a variable (let's call it script). Then, at the end of your script, you add the following code:

```bash
script="plot 'data-file.dat'"

mkfifo $$.gnuplot-pipe
gnuplot -p <$$.gnuplot-pipe & pid=$! exec 3>$$.gnuplot-pipe
echo "$script" >&3

running=1
trap 'running=0' SIGINT
while [[ $running -eq 1 && $(lsof "$1" | wc -l) -gt 0 ]]; do
echo "replot" >&3
	sleep .5s
done

exec 3>&-
rm $$.gnuplot-pipe
wait $pid
```

This code uses a [named pipe](https://en.wikipedia.org/wiki/Named_pipe) to feed data to gnuplot so that we can continue sending commands to gnuplot after launching it. We also use another little-known [trick](http://www.tldp.org/LDP/abs/html/io-redirection.html) to prevent echo from [closing the FIFO](http://stackoverflow.com/a/8436387/472927) file once it has written to it. Because we launched gnuplot as a background process, we can now run our own while loop that sends `replot` messages to gnuplot without blocking the main plotting thread! We can also be somewhat smarter about this by only sending replot commands as long as the file is still held open (the [lsof](https://en.wikipedia.org/wiki/Lsof) command helps us with this), and we can gracefully terminate if the user sends us a SIGINT (presses `^C`). Finally, we close and remove the FIFO file, and wait for gnuplot to terminate. Shiny!

So, there you have it, incremental data plotting in gnuplot without blocking the interface.