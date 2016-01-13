{% extends "default.swig" %}
{% block body %}
<section>
	<ul>
	{% for post in collections.posts %}
		<li>
			<div class="post-date">
				<span>{{ post.date|date("Y-m-d") }}</span>
			</div>
			<div class="title">
				<a href="{{ baseurl }}/{{ post.path }}">{{ post.title }}</a>
			</div>
		</li>
	{% endfor %}
	</ul>
</section>
{% endblock %}
