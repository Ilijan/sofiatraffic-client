#!/usr/bin/perl

package StopsCrawler;

#use strict;
#use warnings;
use WWW::Scripter;
use Data::Dumper;

my(%virtual_table) = (
	url					=> 'http://gps.skgt-bg.com/Web/SelectByLine.aspx',
	transport_type_tag	=> { name => 'ctl00$ContentPlaceHolder1$ddlTransportType' },
	lines_tag 			=> { name => 'ctl00$ContentPlaceHolder1$ddlLines' },
	routes_tag			=> { name 				=> 'ctl00$ContentPlaceHolder1$rblRoute',
							 routes_ids			=> ['ctl00_ContentPlaceHolder1_rblRoute_0',
													'ctl00_ContentPlaceHolder1_rblRoute_1']
							},
	stops_tag			=> { name => 'ctl00$ContentPlaceHolder1$ddlStops' },
	stop_name_tag		=> { id => 'ctl00_ContentPlaceHolder1_lblStopName'},
	stop_desc_tag		=> { id => 'ctl00_ContentPlaceHolder1_lblDescription' },
	stop_image_map_tag	=> { name => 'ctl00$ContentPlaceHolder1$imgMap' }
);

#returns hash: keys are site text, values are option values
sub _get_select_options($$)
{
	my($w, $tag_name) = @_;
	my(@options, $result);
	$result = {};
	@options = $w->document->getElementsByName($tag_name)->[0]->options;
	
	foreach(@options)
	{
		if($tag_name eq $virtual_table{stops_tag}{name}) {print '-'.$_->value."-\n";}		#fix all empty
		if($_->value eq '') {next;}
		
		$result->{$_->value} = $_->text;
	}
	
	return $result;
}

sub _choose_route_by_id($)
{
	my ($w) = @_;
	$w->eval('document.getElementById(\'ctl00_ContentPlaceHolder1_rblRoute_0\').checked = true;', 'JavaScript');
}

#HTML::DOM::Element:: have no class for span tag
sub _extract_stop_desc($)
{
	my($w) = @_;
	my($result, $source, $id);
	$result = '';
	$source = $w->content;
	$id = quotemeta $virtual_table{stop_desc_tag}{id};
	if($source =~ /<span id="$id">(.*?)<\/span>/s)
	{
		$result = $1;
	}
	
	return $result;
}

sub _add_transport_info($$)
{
	my($stop_data, $transport_info) = @_;
	
	if($transport_info->{transport_type} == 1)      { push $stop_data->{transport}->{bus}, $transport_info->{line}; }
	elsif($transport_info->{transport_type} == 0)   { push $stop_data->{transport}->{tram}, $transport_info->{line}; }
	elsif($transport_info->{transport_type} == 2)   { push $stop_data->{transport}->{trolley_bus}, $transport_info->{line}; }
	
	return $stop_data;
}

sub _extract_info_for_stop($$)
{
	my($w, $stop) = @_;
	my($result, $code, $name);
	$result = {};
	
	if($stop =~ /^\((\d+)\) (.*)$/)
	{
		$code = $1;
		$name = $2;
		
		$result->{code} = $code;
		$result->{name} = $name;
		
		$result->{desc} = _extract_stop_desc($w);
		$result->{img_map} = $w->document->getElementById($virtual_table{stop_image_map_tag}{id})->src;
	}
	
	return $result;
}

sub _populate_stop_results($$)
{
	my($results, $stop_info) = @_;
	my($id) = $stop_info->{code};
	
	$result->{$id} //= {};
	#delete $stop_info->{code};
	$result->{$id} = {%{$result->{$id}}, %$stop_info};
}

sub _get_on_ground_transport_info
{
	my($result, $transport_types, $transport_lines, $transport_stops, $stop_info);
	$result = {};
	
	$w = WWW::Scripter->new;
	$w->use_plugin('JavaScript');
	
	$w->get($virtual_table{url});
	
	$transport_types = _get_select_options($w, $virtual_table{transport_type_tag}{name});
	foreach $transport_type (keys %$transport_types)
	{
		$w->select($virtual_table{transport_type_tag}{name}, $transport_type);
		$w->submit();
		
		$transport_lines = _get_select_options($w, $virtual_table{lines_tag}{name});
		foreach $line_num_value (keys %$transport_lines)
		{
			$w->select($virtual_table{lines_tag}{name}, $line_num_value);
			$w->submit();
			
			foreach $route_id (@{$virtual_table{routes_tag}{routes_ids}})
			{
				$w->eval('document.getElementById(\''.$route_id.'\').checked = true;', 'JavaScript');
				print "asd1\n";
				$transport_stops = _get_select_options($w, $virtual_table{stops_tag}{name});	#empty hash
				foreach $stop (keys %$transport_stops)
				{
					$w->select($virtual_table{stops_tag}{name}, $stop);
					$w->submit();
					
					$stop_info = _extract_info_for_stop($w, $stop);
					$stop_info = _add_transport_info($stop_info, {transport_type => $transport_type, line => $line_num_value});
					_populate_stop_results($result, $stop_info);
				}
			}
		}
	}
	
	return $result;
}
#sub _get_metro_info


# return format
# { stop_code1 => { code => 'code', name => 'name', desc => 'description', img_map => 'map_image_url', 
#					transport => { 
#									bus =>  [line1, line2, ...],
#									tram => [line1, line2, ...],
#									trolley_bus => [line1, line2, ...]
#				  }
#   stop_code2 => { ... }
#   ...
# }

sub get_stops_info
{
	_get_on_ground_transport_info;
}

1;
