#!/usr/local/bin/perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}
use Mac::Conversions;
$loaded = 1;
$count = 1;

print "ok $count\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

if (-e "earthrise.jpg.bin" && ! -e "earthrise.jpg") {
    print << "EOBLURB";
    Before this test can be run, earthrise.jpg.bin must be decoded.
    Please drop earthrise.jpg.bin onto any MacBinary decoder,
    for example Stuffit Expander.
EOBLURB
    exit(0);
}
my $cn = Mac::Conversions->new;

$cn->binhex("earthrise.jpg");
$cn->macbinary("earthrise.jpg");

#Test 2: test invertability of BinHex
$cn->debinhex("earthrise.jpg.hqx");
binary_compare("earthrise.jpg","earthrise.jpg.1",++$count);
unlink("earthrise.jpg.1");

#Test 3: test invertability of MacBinary II
$cn->demacbinary("earthrise.jpg.bin");
binary_compare("earthrise.jpg","earthrise.jpg.1",++$count);
unlink("earthrise.jpg.1");

#Test 4: test macb2hex
$cn->macb2hex("earthrise.jpg.bin");
$cn->debinhex("earthrise.jpg.1.hqx");
binary_compare("earthrise.jpg","earthrise.jpg.1",++$count);
unlink("earthrise.jpg.1.hqx");
unlink("earthrise.jpg.1");

#Test 5: test hex2macb
$cn->hex2macb("earthrise.jpg.hqx");
$cn->demacbinary("earthrise.jpg.1.bin");
binary_compare("earthrise.jpg","earthrise.jpg.1",++$count);

#Test 6, 7: test is_macbinary
print "not " unless $cn->is_macbinary("earthrise.jpg.bin");
print "ok ",++$count,"\n";

print "not " if $cn->is_macbinary("README");
print "ok ",++$count,"\n";


unlink("earthrise.jpg.1.bin");
unlink("earthrise.jpg.1");
unlink("earthrise.jpg.bin");
unlink("earthrise.jpg.hqx");

#Tests 8, 9, 10: Make sure that headerless MacBinaries don't make it through
#First create an empty file
open(TST,">empty.bin");
close(TST);
eval {
    $cn->demacbinary("empty.bin");
};

print "not " unless $@ =~ /Headerless/;
print "ok ",++$count,"\n";
eval {
    $cn->macb2hex("empty.bin");
};

print "not " unless $@ =~ /Headerless/;
print "ok ",++$count,"\n";

print "not " if $cn->is_macbinary("empty.bin");
print "ok ",++$count,"\n";

unlink "empty.bin";

sub binary_compare {
    use POSIX;
    use Fcntl;
    
    my ($orig, $copy, $num) = @_;
    my ($buf, $buf2, $n, $fdorig, $fdcopy);
    
    if(open(ORIG,"<$orig") and open(COPY,"<$copy")) {
	while($n = read(ORIG,$buf,2048)) {
	    read(COPY,$buf2,$n);
	    unless ($buf eq $buf2) {
		print "not ok $num";
		return;
	    }
	}
	#print "ok $num\n";
    } else {
	print "not ok $num\n";
	return;
    }
    if($fdorig = POSIX::open($orig,&POSIX::O_RDONLY | &Fcntl::O_RSRC) and
       $fdcopy = POSIX::open($copy,&POSIX::O_RDONLY | &Fcntl::O_RSRC)) {
    $n = POSIX::read($fdorig,$buf,128);
#
#  Matthias says the first 128 bytes of the resource fork are reserved
#  and might be different between OS 7 and OS 8, so skip them
#
	   unless ($n == 128) {
	    print "not ok $num\n";
	    return;
    }
    $n = POSIX::read($fdcopy,$buf2,128);
	   unless ($n == 128) {
	    print "not ok $num\n";
	    return;
    }
	while (($n = POSIX::read($fdorig, $buf, 2048)) > 0) {
	    POSIX::read($fdcopy, $buf2, $n);
	    unless ($buf eq $buf2) {
		print "not ";
		last;
	    }
	}
	print "ok $num\n";
    } else {
	print "not ok $num\n";
    }
}