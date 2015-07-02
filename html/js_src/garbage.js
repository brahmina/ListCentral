var ListHasImages = 0;
var ListHasLinks = 0;
var spinner = "/images/"+themeID+"/LCSpinner.gif";
var LCAvatar = "";

function validateEditList(theForm){

    var Name = document.getElementById("ListName").value;
    if(Name == ""){
        alert("There  list's name cannot be blank");
        document.getElementById("ListName").focus();
        return false;
    }

    var ImagesSelect = document.getElementById('Images');
    if(ListHasImages == 1 && ImagesSelect.options[ImagesSelect.selectedIndex].value == 0){
        var response = confirm("All of the images you have associated with this list will be lost! Are you sure that you want to remove images from this list?");
        return response;
    }

    var LinksSelect = document.getElementById('Links');
    if((ListHasLinks == 1 || ListHasLinks == 2) && LinksSelect.options[LinksSelect.selectedIndex].value == 0){
        var response = confirm("All of the links you have associated with this list will be lost! Are you sure that you want to remove links from this list?");
        return response;
    }

    return true;
}


function getEditListItemFormContent(id, link, status, imageid, imagesrc){
    //alert("in getEditListItemFormContent with id " + id);
    DynamicFormID = DynamicFormID + 1;

    var name = document.getElementById("ListItem" + id + "Span").innerHTML;
    name = name.replace(/'/g, "&#39;");
    var StatusOptions = getStatusOptions(status);
    var editListItemFormContent = "<form method='post' id='EditListItem" + id + "'>" + 
                                  "<div class='FloatingDivTop'>" +
                                  "<div class='FloatingDivBottom'>" +
                                  "<div class='FloatingDiv' id='EditListItem'>" +
                                  "         <h3>Edit List Item Details</h3>" + 
                                  "         <input type='hidden' name='todo' value='ListsManager.EditListItemDetails' id='todo" + DynamicFormID + "'>" + 
                                  "         <input type='hidden' name='ListItem.ID' value='" + id + "' id='ListItemID" + DynamicFormID + "'>" + 
                                  "         <input type='hidden' name='ListDivDisplay' id='ListDivDisplay" + DynamicFormID + "' value='ListEditView'>" +
                                  "         <label>Name:</label><input type='text' name='ListItem.Name' id='Name" + DynamicFormID + "' value='" + name + "' class='TextInput' />" + 
                                  "         <label>Status:</label>" + StatusOptions;
    if(link != ""){
        if(link == "1"){
            link = "";
        }
        editListItemFormContent = editListItemFormContent + 
                                  "         <label>Link:</label><input type='text' name='ListItem.Link' id='Link" + DynamicFormID + "' value='" + link + "' class='TextInput' />";
    }   

    if(imageid != ""){
        var jsOpenWindow = 'javascript:openWindow("upload_image.html?Edit=1&DynamicFormID=' + DynamicFormID + '", "UploadImage", "height=486,width=430,status=yes,toolbar=no,scrollbars=yes");';
        if(imageid == "0"){
            // There is no image but list has images
            editListItemFormContent = editListItemFormContent +
                                  "<div id='EditImageFormElement'>" +
                                  "    <div id='EditImageForm" + DynamicFormID + "' style='display:block'>" +
                                  "        <label for='edituploadimagesubmit' id='EditImageLabel'>Upload an Image:</label>" +
                                  "            <input type='button' name='OpenFileUploader' value='Upload Image' id='edituploadimagesubmit' class='Button' onclick='" + jsOpenWindow + "' />" +
                                  "    </div>" +
                                  "    <div id='EditImageImage" + DynamicFormID + "' style='display:none'>" +
                                  "        <input type='hidden' name='ListItem.ImageID' id='EditUploadedImageID" + DynamicFormID + "' value='' />" +
                                  "        <label for=''EditUploadedImage2>Image:</label><img src='' id='EditUploadedImage2" + DynamicFormID + "' class='EditUploadedImage2' />" +
                                  "        <a href='javascript:cancelImageUploaded(1)' id='RemoveEditImageLink'>Remove Image</a><br /><div class='clear'></div>" +
                                  "    </div>" +
                                  "</div>";
        }else{
            // There is an image
            editListItemFormContent = editListItemFormContent +
                                  "<div id='EditImageFormElement'>" +
                                  "    <div id='EditImageForm" + DynamicFormID + "' style='display:none'>" +
                                  "        <label for='edituploadimagesubmit' id='EditImageLabel'>Upload an Image:</label>" +
                                  "            <input type='button' name='OpenFileUploader' value='Upload Image' id='edituploadimagesubmit' class='Button' onclick='" + jsOpenWindow + "' />" +
                                  "    </div>" +
                                  "    <div id='EditImageImage" + DynamicFormID + "' style='display:block'>" +
                                  "        <input type='hidden' name='ListItem.ImageID' id='EditUploadedImageID" + DynamicFormID + "' value='" + imageid + "' />" +
                                  "        <label>Image:</label><img src='" + imagesrc + "' id='EditUploadedImage2" + DynamicFormID + "' class='EditUploadedImage2' />" +
                                  "        <a href='javascript:cancelImageUploaded(1)' id='RemoveEditImageLink'>Remove Image</a><br /><div class='clear'></div>" +
                                  "    </div>" +
                                  "</div>";
        }
    }

    var descElement = "ListItem" + id +"DescriptionSpan";
    var description = "";
    if(checkobject(descElement)){
        description = document.getElementById(descElement).innerHTML;
        description = description.replace(/<br>/g, "\n");
        description = description.replace(/^\s+/, "");
        if(description != null ){
            editListItemFormContent = editListItemFormContent + 
                                  "         <label>Description:</label><textarea name='ListItem.Description' id='ListItemDescription" + DynamicFormID + "'>" + description + "</textarea>";
        }
    }else{
        editListItemFormContent = editListItemFormContent + 
                                  "         <label>Description:</label><textarea name='ListItem.Description' id='ListItemDescription" + DynamicFormID + "'></textarea>";
    }
    editListItemFormContent = editListItemFormContent + 
                               "            <input type='button' name='Submit' value='Submit' id='editlistitemsubmit'" + DynamicFormID + "' class='Button' onClick='processDynamicForm(this.form)' />" +
                               "            <input type='button' name='Cancel' value='Cancel' id='editlistitemcancel'" + DynamicFormID + "' class='Button' onClick='doNothing()' />" + 
                               "</div></div></div>" +
                               "</form> ";

    var returnform = editListItemFormContent;
    editListItemFormContent = "";

    return returnform;
}

function doServerRequestOld(URL, DivID){

   //alert("in doServerRequest with " + URL + ", " + DivID);

   var http_request = false;
   if (window.XMLHttpRequest) { // Mozilla, Safari,...
        http_request = new XMLHttpRequest();
        //if (http_request.overrideMimeType) {
        //    http_request.overrideMimeType('application/xml');
        //}
    }else if (window.ActiveXObject) { // IE
        try {
            http_request = new ActiveXObject("Msxml2.XMLHTTP");
        }catch (e) {
            try {
                http_request = new ActiveXObject("Microsoft.XMLHTTP");
            }catch (e) {
            }
        }
    }

    if (!http_request) {
        return false;
    }

    http_request.onreadystatechange = function() { 
                                        if(http_request.readyState == 4){
                                            processContents(http_request, DivID); 
                                        }
                                      };

    if(DivID != ""){
        var spinnerContent = getSpinnerContent(DivID, spinner);
        
        var elems = document.getElementById(DivID);
        elems.style.display = '';        
        elems.innerHTML = spinnerContent;
        //alert("DivID: " + DivID);
        //alert("spinner: " + spinnerContent);
        //elems.style.display = '';
        //elems.innerHTML = "<img src='" + spinner + "' alt='Please wait...' />...";
    }

    var splitArray = URL.split('?');
    URL = splitArray[0];
    var params = splitArray[1];
    http_request.open('POST', URL, true);
    var contentType = "application/x-www-form-urlencoded; charset=iso-8859-1";
    http_request.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    //http_request.setRequestHeader("Content-length", params.length);
    //http_request.setRequestHeader("Connection", "close");
    http_request.send(params);
};

function processContents(http_request, PageElement) {

    if (http_request.readyState == 4) {
        try{
            if (http_request.status == 200) {
                var TextResponse = http_request.responseText; 
                //alert("1 TextResponse: " + TextResponse);
                if(PageElement != ""){
                    var elems = document.getElementById(PageElement);
                    elems.innerHTML = TextResponse;
                    launchJavascript(TextResponse);
                }
            }else {
                alert('There was a problem with the request, http status (1): ' + http_request.status + 
                      ", responseText: " + http_request.responseText);
            }
        }catch(e){
            if (http_request.status == 200) {
                var TextResponse = http_request.responseText; 
                //alert("2 TextResponse: " + TextResponse);
                if(PageElement != ""){
                    var elems = document.getElementById(PageElement);
                    elems.innerHTML = TextResponse;
                    launchJavascript(TextResponse);
                }
            }else {
                alert('There was a problem with the request, http status(2) : ' + http_request.status);
            }
        }
    }else{
        alert('ready state failure, ready state: ' + http_request.readyState);
    }

};

function doServerRequestWithFunc(URL, DivName, func){

   var http_request = false;
   if (window.XMLHttpRequest) { // Mozilla, Safari,...
        http_request = new XMLHttpRequest();
        //if (http_request.overrideMimeType) {
        //    http_request.overrideMimeType('application/xml');
        //}
    }else if (window.ActiveXObject) { // IE
        try {
            http_request = new ActiveXObject("Msxml2.XMLHTTP");
        }catch (e) {
            try {
                http_request = new ActiveXObject("Microsoft.XMLHTTP");
            }catch (e) {
            }
        }
    }

    if (!http_request) {
        return false;
    }

    http_request.onreadystatechange = function() { 
                                        if(http_request.readyState == 4){
                                            processContents(http_request, DivName); 
                                            if(func != ''){
                                                func();
                                            }
                                        }
                                      };

    if(DivName != ""){
        var elems = document.getElementById(DivName);
        elems.style.display = '';
        var spinnerContent = getSpinnerContent(DivName, spinner);
        elems.innerHTML = spinnerContent;
    }

    var splitArray = URL.split('?');
    URL = splitArray[0];
    var params = splitArray[1];
    http_request.open('POST', URL, true);
    var contentType = "application/x-www-form-urlencoded; charset=iso-8859-1";
    http_request.setRequestHeader("Content-Type", contentType);
    http_request.send(params);
};

var variable = 0;
function doServerRequestReturnToJS(url, params, func){
   var http_request = false;
   if (window.XMLHttpRequest) { // Mozilla, Safari,...
        http_request = new XMLHttpRequest();
        //if (http_request.overrideMimeType) {
        //    http_request.overrideMimeType('application/xml');
        //}
    }else if (window.ActiveXObject) { // IE
        try {
            http_request = new ActiveXObject("Msxml2.XMLHTTP");
        }catch (e) {
            try {
                http_request = new ActiveXObject("Microsoft.XMLHTTP");
            }catch (e) {
            }
        }
    }

    if (!http_request) {
        return false;
    }

    http_request.onreadystatechange = function() { 
                                        if(http_request.readyState == 4){
                                            var TextResponse = http_request.responseText; 
                                            variable = TextResponse;
                                            func(); 
                                        }
                                      };

    http_request.open('POST', url, true);

    http_request.send(params);
}

function launchJavascript(responseText) {

  //alert("in launchJavascript with " + responseText);

  // RegExp from prototype.sonio.net
  var js = '';
  var ScriptFragment = '(?:<script.*?>)((\n|.)*?)(?:</script.*?>)';
           
  var match    = new RegExp(ScriptFragment, 'img');
  var scripts  = responseText.match(match);
    if(scripts) {
        var js = '';
        for(var s = 0; s < scripts.length; s++) {
            var match = new RegExp(ScriptFragment, 'im');
            js += scripts[s].match(match)[1];
        }
        js = js.replace(/<!--/g,'').replace(/\/\/-->/g,'');
        eval(js);
    }
}

function SwitchToEditMode(On, ListID){
    if(On == 1){
        document.getElementById("ListNormalView").style.display = "none";
        document.getElementById("ListReorderView").style.display = "none";
        document.getElementById("ListEditView").style.display = "";
        document.getElementById("ListDivDisplay").value = "ListEditView";
    }else{
        document.getElementById("ListDivDisplay").value = "ListNormalView";
        if(listChanged){
            listChanged = 0;
            loadList(ListID)
        }else{
            document.getElementById("ListNormalView").style.display = "";
            document.getElementById("ListReorderView").style.display = "none";
            document.getElementById("ListEditView").style.display = "none";
        }
    }
}

