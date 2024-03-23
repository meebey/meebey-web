#!/usr/bin/perl
package IkiWiki::Plugin::google;

# Google services plugin. Currently allows the inclusion of a search form
# and Google Analytics.

use warnings;
use strict;
use IkiWiki 3.00;
use URI;

sub import {
	hook(type => "getsetup", id => "google", call => \&getsetup);
	hook(type => "checkconfig", id => "google", call => \&checkconfig);
	hook(type => "pagetemplate", id => "google", call => \&pagetemplate);
	hook(type => "format", id => "google", call => \&format);
}

sub getsetup () {
	return
		plugin => {
			safe => 1,
			rebuild => 1,
			section => "web",
		},
		google_sitesearch => {
			type => "boolean",
			example => 1,
			description => "Enable or disable the inclusion of a search form in all pages (default)",
			advanced => 0,
			safe => 1,
			rebuild => 1,
		},
		google_analytics_account => {
			type => "string",
			example => 'UA-00000-0',
			description => "Account/Web Property ID to use by default for Google Analytics code",
			advanced => 0,
			safe => 1,
			rebuild => 1,
		},
}

sub sitesearch_enabled() {
	return 1 unless defined $config{google_sitesearch};
	return $config{google_sitesearch};
}

sub checkconfig () {
	# nothing to do if sitesearch is not enabled
	return unless sitesearch_enabled();

	if (! length $config{url}) {
		error(sprintf(gettext("Must specify %s when using the %s plugin"), "url", 'google'));
	}
	
	# This is a mass dependency, so if the search form template
	# changes, every page is rebuilt.
	add_depends("", "templates/googleform.tmpl");
}

my $form;
sub pagetemplate (@) {
	# nothing to do if sitesearch is not enabled
	return unless sitesearch_enabled();

	my %params=@_;
	my $page=$params{page};
	my $template=$params{template};

	# Add search box to page header.
	if ($template->query(name => "searchform")) {
		if (! defined $form) {
			my $searchform = template("googleform.tmpl", blind_cache => 1);
			$searchform->param(url => $config{url});
			$searchform->param(html5 => $config{html5});
			$form=$searchform->output;
		}

		$template->param(searchform => $form);
	}
}

sub format (@) {
	my %params=@_;

	# Add Google Analytics' javascript to all pages, if an account is defined
	if (defined $config{google_analytics_account}) {
		if (! ($params{content}=~s!^(<body[^>]*>)!$1.ga_js()!em)) {
			# no <body> tag, probably in preview mode
			$params{content}=ga_js().$params{content};
		}
	}
	return $params{content};
}

my $ga_js_cached;
sub ga_js {
	return $ga_js_cached if defined $ga_js_cached;

	return unless defined $config{google_analytics_account};

	my $account = $config{google_analytics_account};

	# This is Google Analytics' standard javascript snippet to include their
	# external javascript file, asynchronously.
	return $ga_js_cached=<<"EOF";
<script type="text/javascript">
<!--//--><![CDATA[//><!--
  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', '$account']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();//--><!]]>
</script>
EOF
}

1
