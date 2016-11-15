module lager.cli;

import std.stdio;

import pils.config;

class Cli
{
    void explain()
    {
        writefln("pint %s", pilsVersion);
        writefln("usage: lager [-s <seed>] config_file target_file");
    }

    void solve() {
        writefln("Placed %s objects in %ss", 911, 0.1);
    }
}

void main()
{
    Cli cli = new Cli();
    cli.explain();
}
