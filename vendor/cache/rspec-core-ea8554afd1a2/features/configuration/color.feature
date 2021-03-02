Feature: Windows may require additional solutions to display color

  The output uses [ANSI escape codes](https://en.wikipedia.org/wiki/ANSI_escape_code) to show text in color.  Windows
  systems (shells) often don't interpret those codes at all.

  If you're on Windows and you see ANSI escape codes in the output
  (something like `[1m [31m` ) and your text isn't in different colors,
  you may need to install a utility so that your Windows shell will
  interpret those codes correctly and show the colors.  Here are some
  popular solutions:

    * [ANSICON](https://github.com/adoxa/ansicon): ANSICON runs 'on top of' cmd or powershell. This is a very
      popular solution. You can set it up so that it's always used whenever
      you use cmd or powershell, or use it only at specific times.

    * Alternatives to cmd.exe or powershell: [ConEmu](http://conemu.github.io/), [Console2](http://sourceforge.net/projects/console/),
      [ConsoleZ](https://github.com/cbucher/console)

    * Unix-like shells and utilities:  [cygwin](https://www.cygwin.com/), [babun](http://babun.github.io/index.html),
      [MinGW](http://www.mingw.org/) (Minimalist GNU for Windows)

  To find out more, search for information about those solutions.
