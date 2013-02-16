#!/usr/bin/perl

# package CaptchaSolver;
# use LWP::Simple;
# use Exporter;
# @ISA = qw(Exporter);
# @EXPORT = qw(solve_img save_img_to_file remove_img_file);

# sub solve_img
# {
	# 0;
# }


#end package CaptchaSolver

#package CaptchaSolver::ManualCaptchaSolver;
package CaptchaSolver;
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(solve_img);

use LWP::Simple;

sub save_img_to_file
{
	my($url) = @_;
	my($data, $filename);
	
	$data = get $url;
	$filename = "image".time().".jpg";
	open (FH, ">$filename");
	binmode (FH);
	print FH $data;
	close (FH);
	
	return $filename;
}

sub remove_img_file
{
	my($filename) = @_;
	
	unlink($filename) == 0;
}

sub solve_img
{
	my($img_url) = @_;
	my($captcha_text, $img_file);
	$img_file = save_img_to_file $img_url;
	
	`start $img_file`;
	print STDERR "Enter captcha: ";
	$captcha_text = <STDIN>;
	chomp $captcha_text;
	
	print '-'.$captcha_text."-\n";
	remove_img_file($img_file);
	
	return $captcha_text;
}

#end package CaptchaSolver::ManualCaptchaSolver