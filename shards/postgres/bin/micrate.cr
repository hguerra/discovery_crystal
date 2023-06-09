#! /usr/bin/env crystal
#
# To build a standalone command line client, require the
# driver you wish to use and use `Micrate::Cli`.
#

require "micrate"
require "pg"

Micrate::DB.connection_url = "postgresql://tasks:tasks@localhost:5432/tasks?schema=public"
Micrate::Cli.run
