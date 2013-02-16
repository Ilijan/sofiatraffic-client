#!/usr/bin/perl

package Geolocating;

use JSON;
use LWP::Simple;
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(get_address_by_coords get_coords_by_address);

#TODO caching results
sub _google_addr_by_coords
{
	my($lat, $lon) = @_;
	my($url, $json, $result);
	$url = "http://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lon&language=bg&sensor=false";
	
	$json = get $url;
	$result = decode_json $json;	#decode_json $utf8_encoded_json_text
	
	if($result->{status} eq 'OK')
	{
		return $result->{results}->[0]->{formatted_address};
	}
	
	return '';
}

#TODO caching results
sub _google_coords_by_addr
{
	my($address) = @_;
	my($formated_address, $url, $json, $result, $location);
	$formated_address = ($address =~ tr/ /+/r);
	$url = "http://maps.googleapis.com/maps/api/geocode/json?address=$formated_address&language=bg&sensor=false";
	
	$json = get $url;
	$result = decode_json $json;	#decode_json $utf8_encoded_json_text
	
	if($result->{status} eq 'OK')
	{
		$location = $result->{results}->[0]->{geometry}->{location};
		return [$location->{lat}, $location->{lng}];
	}
	
	return '';
}

sub get_address_by_coords
{
	my($lat, $lon) = @_;
	
	_google_addr_by_coords $lat, $lon;
}

sub get_coords_by_address
{
	my($address) = @_;
	
	_google_coords_by_addr $address;
}

1;
