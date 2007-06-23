require 'mkmf'

# Disable warnings from ld
$LDFLAGS = "-w"
# turn on warnings from gcc
$CFLAGS = "-pedantic -Wall -Wno-long-long -Winline"

dir_config 'date_performance'
create_makefile 'date_performance'
