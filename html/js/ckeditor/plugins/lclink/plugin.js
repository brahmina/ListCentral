var editor;

CKEDITOR.plugins.add('lclink',{
    init:function(a){
        var cmd = a.addCommand('lclink', {exec:showAddLinkBox})
        a.ui.addButton('lclink',{ label:'Add link', command:'lclink', icon: CKEDITOR.getUrl(this.path + 'images/anchor.png') });
        editor = a;
    }
})

function showAddLinkBox(){

    var inputID = "LinkBox";
    var linkText = editor.getSelection().getNative();
    var addLink = "<h3>Add Link to Description</h3><br/>" +
                  "<div class='ListItemExtraLabel'>Link text:</div><br /><input type='text' name='theLinkText' id='LinkText' value='" + linkText + "'>" +
                  "<div class='ListItemExtraLabel'>Link:</div><br /><input type='text' name='theLink' id='LinkInput' value='http://'>" +
                  "<input type='button' name='LinkAdd' id='LinkAdd' value='Submit' class='Button' onclick='addLinkToCKEditor();'>" +
                  "<input type='button' name='LinkCancel' id='LinkCancel' value='Cancel' class='Button' onclick='removeAddLink();'>" +
                  "<div class='clear'></div>";

    showckAddLinkFloatingBox(addLink, 'LinkBox');
}


function showckAddLinkFloatingBox(innerContent, innerDivID){

    //alert("in showckAddLinkFloatingBox with " + innerDivID);
    var boxContent = "<div id='"+innerDivID+"'><div class='FloatingBox'>" + 
                     "    <div class='FloatBoxHandle' id='ckAddLinkHandle'></div>" +
                     "    <div class='FloatingBoxInner'>" +
                     innerContent + "</div>" +
                     "</div></div>";

    $('ckAddLinkWrapper').innerHTML = boxContent;
    $(innerDivID).set('opacity', 0);
    $('ckAddLinkWrapper').style.display = 'block';
    $(innerDivID).set('opacity', 1);

    handle = $('FloatBoxHandle');
    new Drag.Move(innerDivID, {handle: 'ckAddLinkHandle'});
}

function addLinkToCKEditor(){

    var html = "<a href='" + $('LinkInput').value + "'>" + $('LinkText').value + "</a>";
    editor.insertHtml(html);
    removeAddLink();
}
function removeAddLink(){

    $('ckAddLinkWrapper').style.display = 'none';
}
