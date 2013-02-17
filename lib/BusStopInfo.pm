#!/usr/bin/perl

package BusStopInfo;

# new(db)	TODO capthca support
# get_coords(stop_code) -> array [lat, lon]
# get_nearest(lat, lon, radius) -> array [stop_codes]
# get_transport_info(stop_code) -> hash { bus => {line1 => {time => [time1, time2...], route => '' ...}, tram => {...}, trolley_bus => {...}}
# TODO point to point route
# TODO? routes db

use WWW::Scripter;
use Math::Trig;
use CaptchaSolver;
use utf8;
@ISA = qw(Exporter);
@EXPORT = qw(get_coords get_nearest get_transport_info);

sub new
{
	my($class, $db) = @_;
	my($self) = {
		db => $db,
	};
	
	bless $self, $class;
	return $self;
}

sub get_coords
{
	my($self, $stop_code) = @_;
	my($stop);
	
	$stop = $self->{db}->{$stop_code} // return 0;

	if(defined($stop->{lat}) && defined(exists($stop->{lon})))
	{
		return [$stop->{lat}, $stop->{lon}];
	}
	
	return 0;
}

sub _distance
{
	my($lat1, $lon1, $lat2, $lon2) = @_;
	my($R, $dlat, $dlon, $lat, $lon, $a, $c, $d);
	$R = 6371;	#km
	$dlat = deg2rad($lat2-$lat1);
	$dlat = deg2rad($lat2-$lat1);
	$lat1 = deg2rad($lat1);
	$lat2 = deg2rad($lat2);
	
	$a = sin($dlat/2) ** 2 + sin($dlon/2) ** 2 * cos($lat1) * cos($lat2);
	$c = 2 * atan2(sqrt($a), sqrt(1-$a));
	$d = $R * $c;
	
	return $d;#in km
}

sub get_nearest
{
	my($self, $lat, $lon, $radius) = @_;
	my($result, $coords, @delta, @square);
	$result = [];
	
	foreach $stop_code ($self->{db})
	{
		$coords = get_coords $stop_code;
		if($coords)
		{
			$distance = _distance $lat, $lon, $coords[0], $coords[1];#$square[0] + $square[1];
			if($distance < $radius)
			{
				push @$result, $stop_code;
			}
		}
	}
	
	return 0 if $#$result < 0;
	
	return $result;
}

sub _mobile_submit_form
{
	my($w) = @_;
	@captcha_img = grep { $_->src =~ /captcha/ } $w->document->getElementsByTagName('img');
	if($#captcha_img >= 0)
	{
		$captcha_url = 'http://m.sofiatraffic.bg'.$captcha_img[0]->src;
		$solved = solve_img $captcha_url;
		
		#$w->document->getElementById('sc')->value($solved);
		$w->eval("document.getElementById(\"sc\").value = '".$solved."';", 'JavaScript');
	}
	
	@submit_button = grep { $_->type =~ /submit/ } $w->document->getElementsByTagName('input');	#&& $_->value =~ /Провери/
	$submit_button[0]->click;
}

sub _mobile_extract_info_for
{
	my($w, $class_attr) = @_;
	my($result, @vehicles);
	$result = {};
	
	@vehicles = $w->document->getElementsByClassName($class_attr);
	if($#vehicles >= 0)
	{
		foreach $vehicle (@vehicles)
		{
			$inner_html = $vehicle->innerHTML;
			my @lines = grep { length } split (/\n/, $inner_html);
			if($lines[0] =~ /<b>(.*?)<\/b>/)
			{
				$number = $1;
			}
			if($lines[1] =~ /^(.*?)<br/) 
			{
				$times = ($1 =~ s/^\s+|\s+$//rg);	#trim, the /g flag, the substitution makes all possible matches, so it gets both
			}
			
			$route = ($lines[2] =~ s/^\s+|\s+$//rg); # trim
			
			my @times_split = split(',', $times);
			$result->{$number} = {time => \@times_split, route => $route};
		}
	}
	
	return $result;
}

# class="arr_info_2" trolley bus
# class="arr_info_1" bus
# class="arr_info_3" tram
sub _mobile_extract_results
{
	my($w) = @_;
	my($result, $text, $buses, $trams, $trolley_buses, $inner_html, $number, $times, $route);
	$result = {};
	
	$buses = _mobile_extract_info_for $w, "arr_info_1";
	$result->{bus} = $buses;
	$trams = _mobile_extract_info_for $w, "arr_info_3";
	$result->{tram} = $trams;
	$trolley_buses = _mobile_extract_info_for $w, "arr_info_2";
	$result->{trolley_bus} = $trolley_buses;

	return $result;
}

sub _mobile_get_stop_info
{
	my($stop_code) = @_;
	my($w, $mobile_page, @captcha_img, $captcha_url, $solved, @submit_button, $result, @error);
	$mobile_page = 'http://m.sofiatraffic.bg/vt';
	
	$w = WWW::Scripter->new;
	$w->use_plugin('JavaScript');
	
	$w->get($mobile_page);
	
	$w->eval("document.getElementsByName(\"q\")[0].value = ".$stop_code.";", 'JavaScript');
	
	_mobile_submit_form $w;
	
	@error = $w->document->getElementsByClassName('error');
	if($#error >= 0)
	{
		my $err_msg = ($error[0]->innerHTML =~ s/^\s+|\s+$//rg);
		if(length($err_msg) > 0)
		{
			return {};
		}
	}
	
	$result = _mobile_extract_results $w;
	#$w->text =~ /Информация към (.*?)\($stop_code\)/;
	#my $stop_header = $1 // '';
	#$reuslt->{stop_header} = $stop_header;
	return $result;
}

sub get_transport_info
{
	my($self, $stop_code) = @_;
	
	_mobile_get_stop_info($stop_code);
}

1;