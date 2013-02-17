#!/usr/bin/perl

package SofiaTrafficClient;

use BusStopInfo;
use StopsDB;
use Geolocating;
use utf8;

# new
# stop_info($code) -> BusStopInfo->get_transport_info($code)
# nearest_stops_info($lat, $lon, $radius=0.250km) -> hash {code1 => stop_info(code1), code2 => stop_info(code2), ...}
# nearest_stops_info_by_addr($addr, $radius=0.250km) -> hash same as nearest_stops_info
# 

sub new
{
	my($class, $db_file) = @_;
	my($self, $db);
	$db_file //= 'db.xml';
	
	$db = StopsDB->new;
	$db->load_file($db_file);
	
	$stop_info = BusStopInfo->new($db);
	
	$self = {
		db => $db,
		stop_info => $stop_info,
	};
	
	bless $self, $class;
	return $self;
}

sub stop_info
{
	my($self, $code) = @_;
	
	$self->{stop_info}->get_transport_info($code);
}

sub nearest_stops_info
{
	my($self, $lat, $lon, $radius) = @_;
	my(@codes, $result);
	$radius //= 0.250;
	$result = {};
	
	@codes = $self->{stop_info}->get_nearest($lat, $lon, $radius);
	foreach $code (@codes)
	{
		$result->{$code} = $self->stop_info($code);
	}
	
	return $result;
}

sub nearest_stops_info_by_addr
{
	my($self, $addr, $radius) = @_;
	my($addr_coords);
	$radius //= 0.250;
	
	$addr_coords = get_coords_by_address($addr);
	if(!$addr_coords)
	{
		return {};
	}
	
	return $self->nearest_stops_info(@$addr_coords, $radius);
}

1;