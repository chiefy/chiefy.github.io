{% assign url = '/assets/static/' | append: include.file %}
<a href="{{ site.baseurl }}{{url}}" target="_blank" class="image">
	<img src="{{ site.baseurl }}{{url}}" alt="{% if include.alt %}{{ include.alt }}{% else %}Image{% endif %}">
</a>
