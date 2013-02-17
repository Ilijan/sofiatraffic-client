#!/usr/bin/perl

use StopsCrawler;
use StopsDB;
use Data::Dumper;

#my $stops = StopsCrawler->get_stops_info;
#print Dumper($stops);
my $db = StopsDB->new;
#$db->set_db($stops);
$db->populate_from_file('coordinates.xml');
$db->save_to('db.xml');
