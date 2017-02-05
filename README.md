# lager
*lager* is a command line tool for procedural layout solving. You can use
it for offline generation of room layouts or integrate it for use at runtime in your game or visualization.

## Usage
    Usage: lager [--help] [--in=<string>] [--out=<string>] catalog_path

    Positional arguments:
    catalog_path    Global catalog name or a path to a c˘atalog directory to use for placement.

    Optional arguments:
    --help, -h      Prints this help.
    --in, -i <string>
                 The file to read placement instructions in JSON format from.
                 Uses stdin if omitted.
    --out, -o <string>
                 The target file to write the room layout to. Uses stdout if
                 omitted.˘
