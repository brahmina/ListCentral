Request.HTML.implement({
 
        processHTML: function(text){
            var match = text.match(/<body[^>]*>([\s\S]*?)<\/body>/i);
            text = (match) ? match[1] : text;
           
            var container = new Element('div');
           
            return $try(function(){
                var root = '<root>' + text + '</root>', doc;
                if (Browser.Engine.trident){
                    doc = new ActiveXObject('Microsoft.XMLDOM');
                    doc.async = false;
                    doc.loadXML(root);
                } else {
                    doc = new DOMParser().parseFromString(root, 'text/html');
                }
                root = doc.getElementsByTagName('root')[0];
                for (var i = 0, k = root.childNodes.length; i < k; i++){
                    var child = Element.clone(root.childNodes[i], true, true);
                    if (child) container.grab(child);
                }
                return container;
            }) || container.set('html', text);
        }
   
    });
