{% extends "default.swig" %}
{% block title %}{{ title }}{% endblock %}
{% block body %}
<article>
	<h1 class="title">{{ title }}</h1>
	<div class="divider"></div>
	{{ contents | safe }}
</article>
{% include "includes/back.swig" %}
{% endblock %}
