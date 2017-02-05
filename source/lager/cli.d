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
            validateOptionValues();
            generate();
            exitCode = 0;
        }
        catch(ArgParseError e)
        {
            writeln(usage);
            stderr.writeln(e.msg);
        }
        catch(ArgParseHelp e)
        {
            // Help was requested
            stderr.writefln("lager %s", pilsVersion);
            stderr.writeln(usage);
            stderr.writeln(help);
            exitCode = 0;
        }
        catch(Exception e)
        {
            stderr.writefln("ERROR: %s", e.msg);
        }

        return exitCode;
    }

    void validateOptionValues() {}

    void generate() {
        StopWatch sw;

        sw.start();

        stderr.writefln("Solving layout with entity library %s", options.catalogPath);
        initPlanner();
        solveLayout();
        writeLayout();

        sw.stop();

        auto msecDuration = sw.peek().msecs();

        stderr.writefln("🍺  Placed %s objects in %sms 🍺 ", planner.layout.entities.length, msecDuration);
    }

    void explain()
    {
        stderr.writefln("lager %s", pilsVersion);
        stderr.writefln("usage: lager config_file target_file");
    }

    void initPlanner()
    {
        // Initialize planner and catalog with global options
        auto lib = new Catalog(options.catalogPath);
        planner = new Planner(lib);
    }

    void solveLayout()
    {
        if(options.procedureFilePath.empty)
        {
            // TODO If no input path, for now just perform test placements,
            // in the future should read from stdin
            stderr.writeln("WARNING: JSON reading from stdin is unsupported as of now, supply a --in file instead for now, will use livingroom.json for testing instead");
            options.procedureFilePath = "/Users/phil/Development/lager/examples/procedures/livingroom.json";
        }

        stderr.writefln("Reading layout procedure from %s", options.procedureFilePath);
        auto jsonSource = options.procedureFilePath.readText();
        auto steps = fromJSON!(PlanningStep[])(parseJSON(jsonSource));
        planner.submit(steps);
    }

    void writeLayout()
    {
        string layoutJson = planner.layout.json;

        if(options.targetFilePath !is null)
        {
            options.targetFilePath.write(layoutJson);
            stderr.writefln("Written layout to target file %s", options.targetFilePath);
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

class CliOptionException : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}
