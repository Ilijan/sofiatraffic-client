#!/usr/bin/perl

package StopsDB;

sub save_stops_info($$)
{
	my($file, $list) = @_;
	
	
}

sub new($);#hash {DB file, file_format(xml,csv...) }
sub load($);#
sub save();#save to current open db
sub saveTo($);# hash {file_name, file_format(xml,csv...)}
sub populate($);#hash {input_file, file_format(xml,csv...)}, populate only with the exsting fields in input_file(creating new entries and updating old if needed)