#!/usr/bin/perl

use Getopt::Long;
use lib 'lib';
use SofiaTrafficClient;

sub print_useage
{
	print "Useage: $0 [--db db_file | --code id | --nearstops lat lon [radius=0.250] | --nearaddr lat lon [radius=0.250]]\n";
	print "       --db db_file\n";
	print "              optional takes database filename\n";
	print "       --code id\n";
	print "              shows information for stop with given id code\n";
	print "       --nearstops lat lon [radius=0.250]\n";
	print "              gives information for all stops within the radius of given lat-lon coordinates\n";
	print "       --nearaddr lat lon [radius=0.250]\n";
	print "              gives information for all stops within the radius of given address\n";
}

sub print_stop_info
{
	my($stop_info) = @_;
	
	#print $stop_info->{stop_header}."\n";
	
	foreach $vehicle_type (keys  %$stop_info)
	{
		if(!%{$stop_info->{$vehicle_type}})
		{
			next;
		}
		
		if($vehicle_type eq 'tram')
		{
			print "Trams:\n";
		}
		elsif($vehicle_type eq 'bus')
		{
			print "Buses:\n";
		}
		elsif($vehicle_type eq 'trolley_bus')
		{
			print "Trolleys:\n";
		}
		
		foreach $line (keys %{$stop_info->{$vehicle_type}})
		{
			print "-$line: ";
			#print Data::Dumper::Dumper($stop_info->{$vehicle_type}->{$line}->{time});
			print join(',', @{$stop_info->{$vehicle_type}->{$line}->{time}});
			print "\n";
		}
	}
}

MAIN: {
	if($#ARGV == -1)
	{
		print_useage();
		exit 0;
	}
	my $db = 'db.xml';
	my($code, $nearest_stops, $near_addr, $lat, $lon, $radius);
	$radius = 0.250;
	
	GetOptions(
				"db:s"			=> \$db,
				"code:i"		=> \$code,
				"nearstops"		=> \$nearest_stops,
				"nearaddr:s"	=> \$near_addr,
				"lat:i"			=> \$lat,
				"lon:i"			=> \$lon,
				"radius:i"		=> \$radius,
				);
							
	
	
	my $client = SofiaTrafficClient->new($db);
	
	if($code != 0)
	{
		$stop_info = $client->stop_info($code);
		
		print_stop_info $stop_info;
	}
	elsif($nearest_stops && $lat && $lon && $radius)
	{
		$stops = $client->nearest_stops_info($lat, $lon, $radius);
		
		foreach(@$stops)
		{
			print_stop_info $_;
		}
	}
	elsif($near_addr && $radius)
	{
		$stops =  $client->nearest_stops_info_by_addr($near_addr, $radius);
		
		foreach(@$stops)
		{
			print_stop_info $_;
		}
	}
	else
	{
		print_useage;
		exit 0;
	}
}