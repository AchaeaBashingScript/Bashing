/**
*
*  Base64 encode / decode
*  http://www.webtoolkit.info/
*
**/
 
var Base64 = {
 
	// private property
	_keyStr : "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",
 
	// public method for encoding
	encode : function (input) {
		var output = "";
		var chr1, chr2, chr3, enc1, enc2, enc3, enc4;
		var i = 0;
 
		input = Base64._utf8_encode(input);
 
		while (i &lt; input.length) {
 
			chr1 = input.charCodeAt(i++);
			chr2 = input.charCodeAt(i++);
			chr3 = input.charCodeAt(i++);
 
			enc1 = chr1 &gt;&gt; 2;
			enc2 = ((chr1 &amp; 3) &lt;&lt; 4) | (chr2 &gt;&gt; 4);
			enc3 = ((chr2 &amp; 15) &lt;&lt; 2) | (chr3 &gt;&gt; 6);
			enc4 = chr3 &amp; 63;
 
			if (isNaN(chr2)) {
				enc3 = enc4 = 64;
			} else if (isNaN(chr3)) {
				enc4 = 64;
			}
 
			output = output +
			this._keyStr.charAt(enc1) + this._keyStr.charAt(enc2) +
			this._keyStr.charAt(enc3) + this._keyStr.charAt(enc4);
 
		}
 
		return output;
	},
 
	// public method for decoding
	decode : function (input) {
		var output = "";
		var chr1, chr2, chr3;
		var enc1, enc2, enc3, enc4;
		var i = 0;
 
		input = input.replace(/[^A-Za-z0-9\+\/\=]/g, "");
 
		while (i &lt; input.length) {
 
			enc1 = this._keyStr.indexOf(input.charAt(i++));
			enc2 = this._keyStr.indexOf(input.charAt(i++));
			enc3 = this._keyStr.indexOf(input.charAt(i++));
			enc4 = this._keyStr.indexOf(input.charAt(i++));
 
			chr1 = (enc1 &lt;&lt; 2) | (enc2 &gt;&gt; 4);
			chr2 = ((enc2 &amp; 15) &lt;&lt; 4) | (enc3 &gt;&gt; 2);
			chr3 = ((enc3 &amp; 3) &lt;&lt; 6) | enc4;
 
			output = output + String.fromCharCode(chr1);
 
			if (enc3 != 64) {
				output = output + String.fromCharCode(chr2);
			}
			if (enc4 != 64) {
				output = output + String.fromCharCode(chr3);
			}
 
		}
 
		output = Base64._utf8_decode(output);
 
		return output;
 
	},
 
	// private method for UTF-8 encoding
	_utf8_encode : function (string) {
		string = string.replace(/\r\n/g,"\n");
		var utftext = "";
 
		for (var n = 0; n &lt; string.length; n++) {
 
			var c = string.charCodeAt(n);
 
			if (c &lt; 128) {
				utftext += String.fromCharCode(c);
			}
			else if((c &gt; 127) &amp;&amp; (c &lt; 2048)) {
				utftext += String.fromCharCode((c &gt;&gt; 6) | 192);
				utftext += String.fromCharCode((c &amp; 63) | 128);
			}
			else {
				utftext += String.fromCharCode((c &gt;&gt; 12) | 224);
				utftext += String.fromCharCode(((c &gt;&gt; 6) &amp; 63) | 128);
				utftext += String.fromCharCode((c &amp; 63) | 128);
			}
 
		}
 
		return utftext;
	},
 
	// private method for UTF-8 decoding
	_utf8_decode : function (utftext) {
		var string = "";
		var i = 0;
		var c = c1 = c2 = 0;
 
		while ( i &lt; utftext.length ) {
 
			c = utftext.charCodeAt(i);
 
			if (c &lt; 128) {
				string += String.fromCharCode(c);
				i++;
			}
			else if((c &gt; 191) &amp;&amp; (c &lt; 224)) {
				c2 = utftext.charCodeAt(i+1);
				string += String.fromCharCode(((c &amp; 31) &lt;&lt; 6) | (c2 &amp; 63));
				i += 2;
			}
			else {
				c2 = utftext.charCodeAt(i+1);
				c3 = utftext.charCodeAt(i+2);
				string += String.fromCharCode(((c &amp; 15) &lt;&lt; 12) | ((c2 &amp; 63) &lt;&lt; 6) | (c3 &amp; 63));
				i += 3;
			}
 
		}
 
		return string;
	}
 
}
