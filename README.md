# Terra 

Terra is made to be a drop-in easy to use and fast interpreted programming language.

## Installation

> ⚠ NOTE <Br>
> TERRA HAS ONLY BEEN TESTED IN WINDOWS <Br>
> REQUIRED ZIG VERSION: 0.11.0^

```bash
git clone https://github.com/lilBluDev/Terra
cd Terra
zig run src/main --
```

or you can use the pre-built exe!

## Cli Usage

`terra` - pull up a console enviroment

`terra help` / `terra [command] -h` - pull up the main help menu or info about a command.

`terra run <file>` - to run and parse a file, you can use `-v` to view the AST.

## Simplefied Planned Syntax

see more within the `docs` folder for syntax and other documentation!

```text
// Comments are ignored by the tokenizer

// imports
import "std";
import "std/println";
import (
    "./foo/bar/test.tr", // import all visible exports from that file
    "./foo/bar/" // looks for "main.tr" file within that directory 
);

// Process entry
pub fn main(args: []str) !void {
    println("Hello World!")
}

```
