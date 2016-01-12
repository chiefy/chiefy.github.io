<!DOCTYPE html>
<html lang="en">
	<head>
		<title>{% block title %}{{ pkg.title }}{% endblock %}</title>
		<meta name="twitter:card" content="{{ pkg.description }}" />
		<meta name="twitter:site" content="@{{ pkg.twitter }}" />
		<meta name="twitter:title" content="{% block title %}{{ pkg.title }}{% endblock %}" />
		<meta name="twitter:description" content="{% block description %}{{ pkg.description }}{% endblock %}">
		<meta name="description" content="{% block description %}{{ pkg.description }}{% endblock %}">
		<link rel="canonical" href="{% block canonical_url %}{{ baseurl }}{% endblock %}">
		{% include "includes/head.swig" %}
	</head>
	<body>
		{% include "includes/header.swig" %}
		<main>
{% block body %}{% endblock %}
		</main>
		</body>
</html>
