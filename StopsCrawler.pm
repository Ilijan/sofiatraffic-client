#!/usr/bin/perl

package StopsCrawler;

#use strict;
#use warnings;

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
	@options = $w->document->getElementsByName($tag_name)->[0];
	
	foreach(@options)
	{
		if($_->value eq '') {continue;}
		
		$result{$_->text} = $result{$_->value};
	}
	
	$result;
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

sub _extract_info_for_stop($$)
{
	my($w, $stop) = @_;
	my($result, $code, $name);
	$result = {};
	
	if($stop =~ /^\((\d+)\) (.*)$/)
	{
		$code = $1;
		$name = $2;
		
		$result{code} = $code;
		$result{name} = $name;
		
		$result{desc} = _extract_stop_desc($w);
		$result{img_map} = $w->document->getElementById($virtual_table{stop_image_map_tag}{id})->src;
	}
	
	return $result;
}

sub _populate_stop_results($$)
{
	my($results, $stop_info) = @_;
	my($id) = $stop_info->{code};
	
	$result->{$id} //= {};
	$result->{$id} = {%{$result->{$id}}, %$stop_info};
}

sub _get_on_ground_transport_info
{
	my($result, $transport_types, $transport_lines, $transport_stops, $stop_info);
	$result = {};
	
	$w = new WWW::Scripter();
	$w->use_plugin('JavaScript');
	
	$w->get($virtual_table{url});
	
	$transport_types = _get_select_options($w, $virtual_table{transport_type_tag}{name});
	foreach $value (values %$transport_types)
	{
		$w->select($virtual_table{transport_type_tag}{name}, $value);
		$w->submit();
		
		$transport_lines = _get_select_options($w, $virtual_table{lines_tag}{name});
		foreach $line_num_value (values %$transport_lines)
		{
			$w->select($virtual_table{lines_tag}{name}, $line_num_value);
			$w->submit();
			
			foreach $route_id ($virtual_table{routes_tag}{routes_ids})
			{
				$w->eval('document.getElementById(\''.$route_id.'\').checked = true;', 'JavaScript');
				
				$transport_stops = _get_select_options($w, $virtual_table{stops_tag}{name});
				foreach $stop (values %$transport_stops)
				{
					$w->select($virtual_table{stops_tag}{name}, $stop);
					$w->submit();
					
					$stop_info = _extract_info_for_stop($w, $stop);
					_populate_stop_results($result, $stop_info);
				}
			}
		}
	}
	
	return $result;
}
#sub _get_metro_info

sub get_stops_info
{
	_get_on_ground_transport_info;
}

1;
