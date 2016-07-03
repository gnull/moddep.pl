#!/usr/bin/env perl

use v5;
use strict;

use Getopt::Long;

my $modinfo = '/sbin/modinfo';
my $verbose;
my $help;

chomp(my $prog = `basename $0`);

my $usage = << "STOP";

$prog - build dependency graph of linux kernel modules.

USAGE:

  $prog [OPTIONS] path/to/module1.ko /path/to/module2.ko ...

The directed graph is printed to STDOUT in the form suitable for `dot`.  If
multiple modules with the same name are given only the first is processed others
are ignored. E.g calling:

  $prog a/x.ko b/x.ko

will process only `a/x.ko` ignoring `b/x.ko`.

OPTIONS:

  --modinfo, -m      modinfo location, defaults to `/sbin/modinfo`
  --verbose, -v      print additional info
  --help, h          show this help

EXAMPLES:

  Show graph of all modules in subdirectories of current directory:

    $prog -v `find -name \*.ko` | dot -Tx11

  She same but saving graph to graph.png:

    $prog -v `find -name \*.ko` | dot -Tpng -o graph.png

STOP


GetOptions ("modinfo=s" => \$modinfo,
	    "verbose"  => \$verbose,
	    "help" => \$help)
    or die("Wrong arguments!\n$usage");

if ($help) {
    print $usage;
    exit 0;
}

sub verb {
    local $, = ' ';
    local $\ = "\n";
    print STDERR "$prog: @_"
	if $verbose;
};

sub uniq {
    my %seen;
    grep !$seen{`basename $_`}++, @_;
}

sub main {
    local $, = ' -> ';
    local $\ = ";\n";

    verb "Assuming modinfo is at $modinfo";

    my @mods = uniq @ARGV;

    verb "Modules to be searched are: @mods";

    foreach my $mod (@mods) {
	my $modname = `basename $mod`;
	chomp($modname);
	$modname =~ s/.ko$//
	    or die "$modname doesn't end with '.ko'";

	my ($deps) = grep /^depends:/, `$modinfo $mod`
	    or die "failed to call `$modinfo $mod`";
	$deps =~ s/^depends:\s+//;
	chomp($deps);
	verb "$modname depends on $deps";

	print qq/$modname [fillcolor=turquoise, style=filled]/;

	print $modname, $_
	    for (split /,/, $deps);
    }
};

print "digraph G {\n";
main;
print "};\n"
