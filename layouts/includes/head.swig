<meta charset="utf-8">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta name="viewport" content="width=device-width, initial-scale=1" />

{% if pkg.google_verify %}
	<meta name="google-site-verification" content="{{ pkg.google_verify }}">
{% endif %}

<link href='https://fonts.googleapis.com/css?family=Open+Sans:400,600' rel='stylesheet' type='text/css'>
<link href='https://fonts.googleapis.com/css?family=Source+Code+Pro' rel='stylesheet' type='text/css'>

<link rel="stylesheet" href="/assets/core.css">
<link rel="stylesheet" href="/assets/social-icons.css">
<link rel="stylesheet" href="/assets/rrssb.css">
<link rel="stylesheet" href="//cdnjs.cloudflare.com/ajax/libs/highlight.js/9.1.0/styles/zenburn.min.css">
<link rel="alternate" type="application/atom+xml" title="{{ pkg.title }}" href="{{ baseurl }}/feed.xml" />
