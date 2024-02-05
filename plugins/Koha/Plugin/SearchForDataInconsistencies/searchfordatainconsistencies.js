var graphs = [];

var saturation = 0.6;
var lightness = 1;
var alpha = 1;

var dict;
var locale;

function get_translations() {
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.onreadystatechange = function() {
	    if (this.readyState == 4 && this.status == 200) {
	        dict = JSON.parse(this.responseText);
			update_translations();
	    }

	};
	xmlhttp.open("GET", "/plugin/Koha/Plugin/SearchForDataInconsistencies/locale.json", true);
	xmlhttp.send();
}

function update_translations() {
	/* For tables */
	var td = document.getElementById('td-preset-0');
	for (var i = 0; td != undefined; i++, td = document.getElementById('td-preset-' + i)) {
		td.innerHTML = localize(td.innerHTML.trim(), locale);
	}
}

function localize(str, loc) {
	if (dict == undefined)
		return str;
	if (!(loc in dict) || !(str in dict[loc]))
		return str;
	return dict[loc][str];
}
