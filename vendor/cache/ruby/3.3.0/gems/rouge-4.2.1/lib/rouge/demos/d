import std.algorithm, std.conv, std.functional,
    std.math, std.regex, std.stdio;

alias round = pipe!(to!real, std.math.round, to!string);
static reFloatingPoint = ctRegex!`[0-9]+\.[0-9]+`;

void main()
{
    // Replace anything that looks like a real
    // number with the rounded equivalent.
    stdin
        .byLine
        .map!(l => l.replaceAll!(c => c.hit.round)
                                (reFloatingPoint))
        .each!writeln;
}
