
ls
=======

Tools for doing things with comic book archive files

Requirements
------------

- A Linux, Unix, or Unix-like environment
- BASH
- file
- ImageMagick (specifically convert)
- libtiff (specifically tiffcp)
- libtiff-tools (specifically tiff2pdf)

### Format-specific Conditional Requirements

These are _only_ required to process archives of the relevant format.

- **cba**:    unace
- **cbr**:    unrar(-free)
- **cbt**:    tar
- **cbz**:    unzip
- **cb7**:    7zr

Usage
-----

./cbx2pdf.sh /path/to/\[comicarchive\].\[format\]

e.g.
    ./cbx2pdf.sh ~/JohnnyTheHomicidalManiacCollection.cbr

produces:
    /path/to/\[comicarchive\].pdf

e.g.
    ~/JohnnyTheHomicidalManiacCollection.pdf

### Advanced Usage

This script knows about its own error codes.  By running it in an OR'd condition, it can report the cause of its errors.

For example:

    ./cbx2pdf.sh /path/to/nonexistent.cbr || ./cbx2pdf.sh diagnose $?

should produce a message like:

   Specified archive does not exist
