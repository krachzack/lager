/++
 + Contains command line interface functionality and the main function.
 +/
module lager.cli;

private
{
    import std.stdio : writeln, writefln, stderr ;
    import std.datetime;
    import std.file;
    import std.string;
    import std.exception : enforce;
    import std.json;

    import pils.config;
    import pils.solving;
    import darg;
    import painlessjson;
}

struct CliOptions
{
    @Option("help", "h")
    @Help("Prints this help.")
    OptionFlag help;

    @Option("verbose", "v")
    @Help("Report additional information about the generation process through stderr.")
    OptionFlag verbose;

    @Option("debug-placements")
    @Help("Instead of reading from either the file provided with --in or from standard input, perform a set of implementation defined debug placements, relying on the user selecting the dustsucker library.")
    OptionFlag debugPlacements;

    @Argument("catalog_path")
    @Help("Global catalog name or a path to a catalog directory to use for placement.")
    string catalogPath;

    @Option("in", "i")
    @Help("The file to read placement instructions in JSON format from. Uses stdin if omitted.")
    string procedureFilePath;

    @Option("out", "o")
    @Help("The target file to write the room layout to. Uses stdout if omitted.")
    string targetFilePath;
}

class Cli
{
private:
    CliOptions options;
    Planner planner;
    enum usage = usageString!CliOptions("lager");
    enum help = helpString!CliOptions;

public:
    int run(string[] args)
    {
        int exitCode = 1;

        try
        {
            options = parseArgs!CliOptions(args[1 .. $]);
            generate();
            exitCode = 0;
        }
        catch(ArgParseError e)
        {
            stderr.writeln(usage);
            stderr.writefln("ERROR: %s", e.msg);
        }
        catch(ArgParseHelp e)
        {
            // Help was requested
            explain();
            exitCode = 0;
        }
        catch(Exception e)
        {
            stderr.writefln("ERROR: %s", e.msg);
        }

        return exitCode;
    }

    void explain()
    {
        stderr.writefln("lager %s", pilsVersion);
        stderr.writeln(usage);
        stderr.writeln(help);
    }

    void generate()
    {
        StopWatch sw;

        sw.start();

        if(options.verbose)
        {
            stderr.writefln("Solving layout with entity library %s", options.catalogPath);
        }

        initPlanner();
        solveLayout();
        writeLayout();

        sw.stop();

        auto msecDuration = sw.peek().msecs();

        if(options.verbose)
        {
            stderr.writefln("🍺  Placed %s objects in %sms 🍺 ", planner.layout.entities.length, msecDuration);
        }
    }

    void initPlanner()
    {
        // Initialize planner and catalog with global options
        auto lib = new Catalog(options.catalogPath);
        planner = new Planner(lib);
    }

    void solveLayout()
    {
        if(options.debugPlacements)
        {
            stderr.writeln("DEBUG: Trying to read from /Users/phil/Development/lager/examples/procedures/livingroom.json " ~
                           "in response to --debug-placements");
            options.procedureFilePath = "/Users/phil/Development/lager/examples/procedures/livingroom.json";
        }

        if(options.procedureFilePath.empty)
        {
            enforce(false, "Sorry, reading from standard input is unsupported as of yet");
        }
        else
        {
            if(options.verbose)
            {
                stderr.writefln("Reading layout procedure from %s", options.procedureFilePath);
            }

            auto jsonSource = options.procedureFilePath.readText();
            auto steps = fromJSON!(PlanningStep[])(parseJSON(jsonSource));
            planner.submit(steps);
        }
    }

    void writeLayout()
    {
        string layoutJson = planner.layout.json;

        if(options.targetFilePath !is null)
        {
            options.targetFilePath.write(layoutJson);
            if(options.verbose)
            {
                stderr.writefln("Written layout to target file %s", options.targetFilePath);
            }
        }
        else
        {
            // Write to stdout if no output file specified
            writeln(layoutJson);
        }
    }
}

int main(string[] args)
{
    Cli cli = new Cli();
    return cli.run(args);
}

class CliOptionException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
    }
}
