#! /usr/bin/perl

use Date::Parse;
use Config::General;
use Getopt::Long;
use Text::Wrap;
use POSIX qw(strftime);
use strict;
use warnings;

my $do_preamble;
my $do_verify;
my $verbose;
my $configfile = "$ENV{HOME}/.procmail/vacation.cfg";

$Text::Wrap::columns = 78;

GetOptions(
    "verify"	=> \$do_verify,
    "verbose"	=> \$verbose,
    "preamble"	=> \$do_preamble,
);

my $confobj = Config::General->new($configfile);
die "$configfile: unable to load configuration\n" unless defined($confobj);
my %CONFIG = $confobj->getall;

my @vacation;
if (exists($CONFIG{vacation})) {
    if (ref($CONFIG{vacation}) eq 'ARRAY') {
	@vacation = @{$CONFIG{vacation}};
    }
    else {
	@vacation = ( $CONFIG{vacation} );
    }
}

if ($do_verify) {
    for my $v (@vacation) {
	if ($verbose) {
	    warn "checking sdate='$v->{sdate}', edate='$v->{edate}'\n";
	}
	my $sdate = str2time($v->{sdate});
	if (not defined($sdate)) {
	    warn "$v->{sdate}: invalid format\n";
	}
	my $edate = str2time($v->{edate});
	if (not defined($edate)) {
	    warn "$v->{edate}: invalid format\n";
	}

	if (defined($sdate) and defined($edate) and $sdate >= $edate) {
	    warn "$v->{sdate} >= $v->{edate}\n";
	}
    }
}
else {
    for my $v (@vacation) {
	my $sdate = str2time($v->{sdate});
	if (not defined($sdate)) {
	    warn "error: $v->{sdate}: bad format\n";
	    print "no\n";
	    exit;
	}
	my $edate = str2time($v->{edate});
	if (not defined($edate)) {
	    warn "error: $v->{edate}: bad format\n";
	    print "no\n";
	    exit;
	}
	my $time = time;
	if ($time >= $sdate and $time < $edate) {
	    if ($do_preamble) {
		print wrap('', '', subst($v->{preamble}, $v)), "\n";
	    }
	    else {
		print "yes\n";
	    }
	    exit;
	}
    }
    print "no\n" unless $do_preamble;
}

sub subst {
    my $text = shift;
    my $vars = shift;

    $text =~ s/\@\@([^@]+)\@\@/subst_one($1,$vars)/ge;

    return $text;
}

sub subst_one {
    my $name = shift;
    my $vars = shift;
    my $result = '@@' . $name . '@@';	# default

    my ($base,$filter) = split(/\|/, $name, 2);
    if ($base =~ /^[se]date$/) {
	my $time = str2time($vars->{$base});
	$result = strftime(defined($filter) ? $filter : "%a, %b %e", localtime($time));
    }

    # trim leading/trailing whitespace
    $result =~ s/^\s*//;
    $result =~ s/\s*$//;

    return $result;
}
