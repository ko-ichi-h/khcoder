/* Usage:
 *  jQuery.csv()(csvtext)               returns an array of arrays representing the CSV text.
 *  jQuery.csv("\t")(tsvtext)           uses Tab as a delimiter (comma is the default)
 *  jQuery.csv("\t", "'")(tsvtext)      uses a single quote as the quote character instead of double quotes
 *  jQuery.csv("\t", "'\"")(tsvtext)    uses single & double quotes as the quote character
 */
;
jQuery.extend({
    csv: function(delim, quote, linedelim) {
        delim = typeof delim == "string" ? new RegExp( "[" + (delim || ","   ) + "]" ) : typeof delim == "undefined" ? ","    : delim;
        quote = typeof quote == "string" ? new RegExp("^[" + (quote || '"'   ) + "]" ) : typeof quote == "undefined" ? '"'    : quote;
        lined = typeof lined == "string" ? new RegExp( "[" + (lined || "\r\n") + "]+") : typeof lined == "undefined" ? "\n" : lined;

        function splitline (v) {
            // Split the line using the delimitor
            var arr  = v.split(delim),
                out = [], q;
            for (var i=0, l=arr.length; i<l; i++) {
                //if (q = arr[i].match(quote)) {
                //    for (j=i; j<l; j++) {
                //        if (arr[j].charAt(arr[j].length-1) == q[0]) { break; }
                //    }
                //    var s = arr.slice(i,j+1).join(delim);
                //    out.push(s.substr(1,s.length-2));
                //    i = j;
                //}
                //else { out.push(arr[i]); }
                 out.push(arr[i]);
            }

            return out;
        }

        return function(text) {
            var lines = text.split(lined);
            for (var i=0, l=lines.length; i<l; i++) {
                lines[i] = splitline(lines[i]);
            }
            return lines;
        };
    }
});