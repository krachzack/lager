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

    import pils.config;
    import pils.planner;
    import darg;
}

struct CliOptions
{
    @Option("help", "h")
    @Help("Prints this help.")
    OptionFlag help;

    @Argument("library_path")
    @Help("Path to the entity library to use for placement")
    string entityLibraryPath;

    @Argument("target_file")
    @Help("The target file to write the room layout to")
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
            writefln("lager %s", pilsVersion);
            writeln(usage);
            writeln(help);
            exitCode = 0;
        }
        catch(Exception e)
        {
            stderr.writefln("ERROR: %s", e.msg);
        }

        return exitCode;
    }

    void validateOptionValues() {
        if(!exists(options.entityLibraryPath)) {
            auto msg = format("Specified entity library path \"%s\" does not exist",
                              options.entityLibraryPath);

            throw new CliOptionException(msg);
        }
    }

    void generate() {
        StopWatch sw;

        sw.start();

        writefln("Solving layout with entity library %s", options.entityLibraryPath);
        initPlanner();
        solveLayout();

        writefln("Written layout to target file %s", options.targetFilePath);
        writeLayout();

        sw.stop();

        auto msecDuration = sw.peek().msecs();

        writefln("🍺  Placed %s objects in %sms 🍺 ", planner.layout.entities.length, msecDuration);
    }

    void explain()
    {
        writefln("pint %s", pilsVersion);
        writefln("usage: lager config_file target_file");
    }

    void initPlanner()
    {
        auto lib = new EntityLibrary(options.entityLibraryPath);
        planner = new Planner(lib);

        // Add starting layout
        planner.instantiate("dustsucker.room", vec3d(0,0,0));
    }

    void solveLayout()
    {
        // Add 2 couches
        planner.place("dustsucker.couch", "Ground", 30);
        // And 5 TVs
        planner.place("dustsucker.tv", "Ground", 70);
    }

    void writeLayout()
    {
        string layoutJson = planner.layout.json;
        options.targetFilePath.write(layoutJson);
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
