{% extends "default.swig" %}
{% block title %}{{pkg.title}} - {{title}}{% endblock %}
{% block description %}{{ excerpt|striptags }}{% endblock %}
{% block canonical_url %}{{ baseurl }}/{{ path }}{% endblock %}
{% block body %}
<article>
	<div class="center">
		<h1>{{ title }}</h1>
		<time>{{ date|date('F jS, Y') }}</time>
	</div>
	<div class="divider"></div>
	{{ contents | safe }}
	{% include "includes/sharing.swig" %}
	{% if env !== 'dev' %}
		{% include "includes/disqus.swig" with { url: pkg.baseurl + path, id: slug } only	 %}
	{% endif %}
</article>
<script src="//cdnjs.cloudflare.com/ajax/libs/highlight.js/9.1.0/highlight.min.js"></script>
<script>hljs.initHighlightingOnLoad();</script>
<script>window.jQuery || document.write('<script src="//ajax.googleapis.com/ajax/libs/jquery/1.10.2/jquery.min.js"><\/script>')</script>
<script src="/assets/js/rrssb.min.js"></script>
<script type="text/javascript">
$(document).ready(function () {
	$('.rrssb-buttons').rrssb({
		title: '{{ title }}',
		url: '{{ baseurl }}/{{ path }}',
		description: '{{ title }}',
		emailBody: 'Check out this link: <a href="{{ baseurl }}/{{ path }}">{{ title }}</a>\n\n{{ excerpt|striptags }}'
	});
});
</script>
{% include "includes/back.swig" %}
{% endblock %}


