function restCall(url, type) {
	let requestedData;
	$.ajax({ 
        type: type,
        dataType: "json",
        url: url,
		success: function(data){ requestedData = data; },
		error: function(message) { alert('Error occurs:', message); },
		async: false
	});
	
	return requestedData;
}