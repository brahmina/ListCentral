//<!--

var themeID;
var myWin;
var themeColours;
var scriptsURL;
var StatusSetSelect;
var imagesMultibox;
var AddAmazonMultibox;   
var EditAmazonMultibox;   
var AddCCImageMultibox;
var EditCCImageMultibox;
var listChanged = 0;
var thisListID = 0;
var ListCreator = "??";
var ListName = "??";
var ButtonID = "";
var spinner = "";
var ThemeColor3 = '#1d687a';
var DynamicFormID = 0;
var editing = 0;
var SortableListArray = new Array();
var ckeditors = new Array(); 
var descriptionContents = new Array();
var listItem = new Array()
listItem["Link"] = 0;
listItem["Description"] = 0;
listItem["Extra"] = 0;

function initOwner(){
        var status = {
		'true': 'open',
		'false': 'close'
	};

    // Sliders
	var formSlide = initSlider();
    
    $('AddListItemButton').addEvent('click', function(e){
        doSlider(e, formSlide, "AddListItemContent");
	});
	$('CommentsButton').addEvent('click', function(e){
        doSlider(e, formSlide, "CommentsContent");
	});
    $('TagsButton').addEvent('click', function(e){
        doSlider(e, formSlide, "TagsContent");
	});
    $('EditListButton').addEvent('click', function(e){
        doSlider(e, formSlide, "EditListContent");
	});
    $('EmailButton').addEvent('click', function(e){
        doSlider(e, formSlide, "EmailContent");
	});
    $('DeleteButton').addEvent('click', function(e){
        return confirm('Are you sure you are done with this list?');
    });

    initListItemForm("Add");
    doSlider("", formSlide, "AddListItemContent");
}

function escEvent(){
    removeFloatingBox();
    hideLogin();
}

function initMember(){

    // Sliders
    var formSlide = initSlider();

	$('CommentsButton').addEvent('click', function(e){
        doSlider(e, formSlide, "CommentsContent");
	});
    $('EmailButton').addEvent('click', function(e){
        doSlider(e, formSlide, "EmailContent");
	});

    doSlider("", formSlide, "CommentsContent");

};
function initGuest(){

    // Sliders
    var formSlide = initSlider();

	$('CommentsButton').addEvent('click', function(e){
        doSlider(e, formSlide, "CommentsContent");
	});
    $('EmailButton').addEvent('click', function(e){
        doSlider(e, formSlide, "EmailContent");
	});

    doSlider("", formSlide, "CommentsContent");

};

function initSlider(){
    var formSlide = new Fx.Slide('FormSlider', {
            duration: 400,
            onComplete: function(){
                if(this.wrapper.getStyle('height') != "0px"){
                    // Prevents it breaking on close
                    this.wrapper.setStyle('height', 'auto');
                    $('ListDetailsText').style.width = '420px';
                }else{
                    $('ListDetailsText').style.width = 'auto';
                }
            }
    }).hide();

    return formSlide;
}


function initListItemForm(action){
    //alert("in initListItemForm " + action);
    // Add link elements

    var button = action + "LinkButton";
    $(button).addEvent('click', function(e){
        e.stop();
        setAddListItemFormElement(action, 'Link');
        disableListItemButton(action, 'Link');
    });
    button = action + "DescriptionButton";
    $(button).addEvent('click', function(e){
        e.stop();
        setAddListItemFormElement(action, 'Description');
        disableListItemButton(action, 'Description');
    });
    button = action + "EmButton";
    $(button).addEvent('click', function(e){
        e.stop();
        setAddListItemFormElement(action, 'Em');
        disableListItemButton(action, 'Em');
    });
    button = action + "ImageButton";
    $(button).addEvent('click', function(e){
        e.stop();
        openWindow('upload_image.html?action=' + action, 'UploadImage','height=486,width=430,status=yes,toolbar=no,scrollbars=yes');
    });

    if(action == "Add"){
        AddAmazonMultibox = new multiBox('AddAmazon', {
            overlay: new overlay(),
            enabled : true
        });
        AddCCImageMultibox = new multiBox('AddCCImage', {
            overlay: new overlay(),
            enabled : true
        });
    }else{
        EditAmazonMultibox = new multiBox('EditAmazon', {
            overlay: new overlay(),
            enabled : true
        });
        EditCCImageMultibox = new multiBox('EditCCImage', {
            overlay: new overlay(),
            enabled : true
        });
    }
}

function loadList(ListID){
    removeFloatingBox();

    // Set the current list's nav
    resetNavigation();
    var currentLiID = "ListNav" + ListID;
    var currentNav = document.getElementById(currentLiID);
    currentNav.onmouseover = ""; 
    currentNav.onmouseout = "";
    currentNav.className = "NavCurrent";

    var url = scriptsURL + "?ListID=" + ListID + "&todo=getList&ajax=1&ListDivDisplay=ListNormalView";
    doServerRequestWithFunc(url, "List", changeDocTitle);    
}
function resetNavigation(){
    var lis = document.getElementsByTagName('li')
    for (var i = 0; i < lis.length; i++){
        //alert("i: " + i +", lis[i] :" + lis[i]);
        if(lis[i].className == "NavCurrent"){
            lis[i].className = "Nav";
            lis[i].onmouseover = function(){changeClass('NavOver', this)}; 
            lis[i].onmouseout = function(){changeClass('Nav', this)};
        }
    }
}
function loadMoreList(ListID, page, Div){
    removeFloatingBox();
    var url = scriptsURL + "?ListID=" + ListID + "&page=" + page + "&todo=getList&ajax=1&ListDivDisplay=ListNormalView";
    doServerRequest(url, Div);    
}

function changeRegions(CountryID){
    var Region = document.getElementById("Region")
    var url = scriptsURL + "?todo=GetRegionOptions&CountryID=" + CountryID + "&ajax=1&ListDivDisplay=ListNormalView";
    spinner = "/images/" + themeID + "/horizontal_spinner.gif"
    doServerRequest(url, "Regions");    
}

function loadNonListElement(todo, UserID){
    removeFloatingBox();

    var url = scriptsURL + "?todo=" + todo + "&UserID=" + UserID + "&ajax=1";
    thisListID = 0;
    window.scroll(0,0);
    doServerRequestWithFunc(url, "List", changeDocTitle);   
}

function loadNonListElement(todo, UserID, param){
    removeFloatingBox();

    resetNavigation();
    var url = scriptsURL + "?todo=" + todo + "&UserID=" + UserID + "&ajax=1&" + param;
    thisListID = 0;
    window.scroll(0,0);
    doServerRequestWithFunc(url, "List", changeDocTitle);   
}

function getListComments(ListID, param){

    var url = scriptsURL + "?todo=getListComments&ListID=" + ListID + "&ajax=1&" + param;
    spinner = "/images/"+themeID+"/horizontal_spinner.gif";
    doServerRequest(url, "ListComments");   
}

function deleteListItem(ListItemID){
    var confirmed = confirm("Are you sure you want to delete this list item?");
    if(confirmed){
        var url = scriptsURL + "?todo=DeleteListItem&ListItemID=" + ListItemID + "&ajax=1";
        doServerRequest(url, "List");
    }
}

function deleteListGroup(ListGroupID){
    var confirmed = confirm("Are you sure you want to delete this list group? All your lists categorized under this list group will be Uncategorized!");
    if(confirmed){
        var url = scriptsURL + "?todo=DeleteListGroup&ListGroupID=" + ListGroupID + "&ajax=1";
        doServerRequest(url, "List");   
    }
}
function deleteStatusSet(StatusSetID){
    var confirmed = confirm("Are you sure you want to delete this status set? All your lists with this status set will have not status!");
    if(confirmed){
        var url = scriptsURL + "?todo=DeleteStatusSet&StatusSetID=" + StatusSetID + "&ajax=1";
        doServerRequest(url, "List");   
    }
}
function deleteComment(CommentID){
    var confirmed = confirm("Are you sure you want to delete this comment?");
    if(confirmed){
        var url = scriptsURL + "?todo=DeleteComment&CommentID=" + CommentID + "&ajax=1";
        spinner = "/images/"+themeID+"/horizontal_spinner.gif";
        doServerRequest(url, "ListComments");   
    }
}
function deleteBoardPost(BoardPostID){
    var confirmed = confirm("Are you sure you want to delete this board post?");
    if(confirmed){
        var url = scriptsURL + "?todo=DeleteBoardPost&BoardPostID=" + BoardPostID + "&ajax=1";
        doServerRequest(url, "List");   
    }
}

function changeDocTitle(){
    if(thisListID == 0){
        document.title = "lc: list central!";
    }else{
        var lname = ListName.replace(/&amp;/gi, "&");
        lname = lname.replace(/&#39;/g, "\'"); 
        lname = lname.replace(/&quot;/g, "\"");
        lname = lname.replace(/&lt;/g, "<");
        lname = lname.replace(/&gt;/g, ">");

        var title = "lc: " + lname  + " a list by " + ListCreator;
        document.title = title;
    }
}

function editListOrder(ListOrder){
    var url = scriptsURL + "?ListOrder=" + ListOrder + "&todo=EditListItemOrder&ajax=1&ListDivDisplay=ListNormalView";
    doServerRequest(url, "List");    
}
function doListRating(Rating, ID){
    spinner = "/images/" + themeID + "/horizontal_spinner.gif"
    var url = scriptsURL + "?todo=doListRating&ListID=" + ID + "&Rating=" + Rating + "&ajax=1";
    var divName = "ListRating_" + ID;
    doServerRequest(url, divName);
}
function SwitchToReorderMode(On){
    if(On == 1){
        document.getElementById("ListNormalView").style.display = "none";
        document.getElementById("ListReorderView").style.display = "";
    }else{
        // Save the ordering!
        var OrderingString = "";
        //for(var i = 0; i < SortableListArray.length; i++){
        for (var sortable in SortableListArray){
            var subSection = sortable.substring(8,0);
            if(subSection == "Sortable"){
                var serialization = SortableListArray[sortable].serialize(function(element, index){
                    return element.getProperty('id').replace('Sortable','') + '-' + index;
                }).join(',');

                OrderingString = OrderingString + serialization + ",";
            }
        }
        editListOrder(OrderingString);
    }
}

function processDynamicForm(theForm){
    var params = getAjaxParams(theForm);

    var url = scriptsURL + "?" + params + "&ajax=1";

    removeFloatingBox();

    doServerRequest(url, "List");   
}
function processForm(theForm){
    
    processForm(theForm, "List");
}
function processAddListItem(theForm){

    saveEditorContent("Add");
    listItem["Link"] = 0;
    listItem["Description"] = 0;
    listItem["Extra"] = 0;

    processForm(theForm, "List");

    return false;
}

function processForm(theForm, divID){

    //alert("in processForm with " + divID);
    var Params = new Array();
    var j = 0;

    var paramsstr = getAjaxParams(theForm);

    var url = scriptsURL + "?" + paramsstr + "&ajax=1";
    //alert("url: " + url);
    removeFloatingBox();
    scroll(0,0);
    doServerRequest(url, divID);

    return false;
}
function AddListTag(theForm, divID){
    var Params = new Array();
    var j = 0;

    var paramsstr = getAjaxParams(theForm);
    var url = scriptsURL + "?" + paramsstr + "&ajax=1";
    spinner = "/images/"+themeID+"/horizontal_spinner.gif";
    document.getElementById('Tag').value = "";
    doServerRequest(url, divID);
    return false;
}
function DeleteListTags(theForm, divID){
    var Params = new Array();
    var j = 0;

    var paramsstr = getAjaxParams(theForm);
    var url = scriptsURL + "?" + paramsstr + "&ajax=1";
    spinner = "/images/"+themeID+"/horizontal_spinner.gif";
    doServerRequest(url, divID);
    return false;
}

function AddListComment(theForm, divID){
    var Params = new Array();
    var j = 0;

    var paramsstr = getAjaxParams(theForm);
    var url = scriptsURL + "?" + paramsstr + "&ajax=1";
    //spinner = "/images/"+themeID+"/horizontal_spinner.gif";
    document.getElementById('Comment').value = "";
    doServerRequest(url, "ListComments");
    return false;
}
function getAjaxParams(theForm){

    //alert("in getAjaxParams with: "+ theForm + ", " + theForm.ID);
    var returnString = "";
    for (var i=0; i < theForm.elements.length; i++) {
        var elementID = theForm.elements[i].id;
        //alert("elementID: " + elementID + ", name: " + theForm.elements[i].name);
        if(checkobject(elementID)){
            var value = getInputValue(theForm.elements[i]);
            //alert("value: " + value);
            if(value == "unchecked"){
                continue;
            }
            var element = theForm.elements[i];

            //alert("checked!: " + value);
            if(element.name == ""){
                //alert("No name element!! " + elementID);
                continue;
            }
            if(value != undefined){
                if(returnString == ""){
                    returnString = element.name + "=" + encodeURIComponent(value);
                }else{
                    returnString = returnString + "&" + element.name + "=" + encodeURIComponent(value);
                }        
            }
        }
    }

    return returnString;
}

function switchSettings(divID){

    document.getElementById('BasicInfo').style.display = "none";
    document.getElementById('SettingsNavLI_BasicInfo').className = "tabsFirst";

    document.getElementById('AboutMe').style.display = "none";
    document.getElementById('SettingsNavLI_AboutMe').className = "tabs";

    document.getElementById('Avatar').style.display = "none";
    document.getElementById('SettingsNavLI_Avatar').className = "tabs";

    document.getElementById('Theme').style.display = "none";
    document.getElementById('SettingsNavLI_Theme').className = "tabs";

    document.getElementById('Emailing').style.display = "none";
    document.getElementById('SettingsNavLI_Emailing').className = "tabs";

    document.getElementById('Privacy').style.display = "none";
    document.getElementById('SettingsNavLI_Privacy').className = "tabsLast";

    if(divID == "BasicInfo"){
        document.getElementById('BasicInfo').style.display = "block";
        document.getElementById('SettingsNavLI_BasicInfo').className = "tabsFirstOn";
    }else if (divID == "AboutMe") {
        document.getElementById('AboutMe').style.display = "block";
        document.getElementById('SettingsNavLI_AboutMe').className = "tabsOn";
    }else if (divID == "Avatar") {
        document.getElementById('Avatar').style.display = "block";
        document.getElementById('SettingsNavLI_Avatar').className = "tabsOn";
    }else if (divID == "Theme") {
        document.getElementById('Theme').style.display = "block";
        document.getElementById('SettingsNavLI_Theme').className = "tabsOn";
    }else if (divID == "Emailing") {
        document.getElementById('Emailing').style.display = "block";
        document.getElementById('SettingsNavLI_Emailing').className = "tabsOn";
    }else if (divID == "Privacy") {
        document.getElementById('Privacy').style.display = "block";
        document.getElementById('SettingsNavLI_Privacy').className = "tabsLastOn";
    }else{
        alert("Something is awry! switchListForm(" + divID + ")");
    }
}
function switchCreateEdit(divID){

    document.getElementById('CreateList').style.display = "none";
    document.getElementById('CreateEditNavLI_CreateList').className = "tabsFirst";

    document.getElementById('ListGroups').style.display = "none";
    document.getElementById('CreateEditNavLI_ListGroups').className = "tabs";

    document.getElementById('StatusSets').style.display = "none";
    document.getElementById('CreateEditNavLI_StatusSets').className = "tabsLast";


    if(divID == "CreateList"){
        document.getElementById('CreateList').style.display = "block";
        document.getElementById('CreateEditNavLI_CreateList').className = "tabsFirstOn";
    }else if (divID == "ListGroups") {
        document.getElementById('ListGroups').style.display = "block";
        document.getElementById('CreateEditNavLI_ListGroups').className = "tabsOn";
    }else if (divID == "StatusSets") {
        document.getElementById('StatusSets').style.display = "block";
        document.getElementById('CreateEditNavLI_StatusSets').className = "tabsLastOn";
    }else{
        alert("Something is awry! switchListForm(" + divID + ")");
    }
}

function getInputValue(element){
    var value;
    var InputID = element.id;
    var InputType = element.type;
    var name = element.name;
    var value = element.value;

    //alert("getInputValue: InputID: " + InputID + ", name: " + element.name + ", value: " + element.value + ", type: " + InputType);

    if((name == "ListItem.Link" && value == "http://") || (name == "ListItem.ImageLink" && value == "Paste a link to a jpg, gif or png file")){
        value = "";
    }else if(InputType == "text" || InputType == "hidden" || InputType == "textarea" ){
        value = element.value;
    }else if(InputType == "button" || InputType == "submit"){
        if((ButtonID == element.name)){
            value = element.value;
        }
    }else if(InputType == "select-one"){
        if(element.selectedIndex >= 0){
            value = element.options[element.selectedIndex].value;
        }else{
            value = "";
        }        
    }else if(InputType == "checkbox" || InputType == "radio"){
        if(element.checked){
            value = element.value;
        }else{
            value = "unchecked";
        }
    }else if(InputType == "file" && element.value != undefined){
        alert("This ain't gonna work!");
    }else{
        //alert("InputType no match: " + element.name + ", of type: " + InputType);
    }

    return value;
}

function doNothing(){
    removeFloatingBox();
}

function showEditListItemForm(ListItemID){
    //alert("in showEditListItemForm with id " + ListItemID);

    removeFloatingBox();

    var divID = "EditListItem" + ListItemID;
    var editListItemForm = "<div id='" + divID + "'></div>";
    showFloatingBox(editListItemForm, 'EditListItemForm');

    var url = scriptsURL + "?todo=GetEditListItemForm&ListItemID=" + ListItemID + "&ajax=1";
    doServerRequest(url, divID);    
}

var handle;
function showFloatingBox(innerContent, innerDivID){

    //alert("in showFloatingBox with " + innerDivID);
    var boxContent = "<div id='"+innerDivID+"'><div class='FloatingBox'>" + 
                     "    <div class='FloatBoxHandle' id='FloatBoxHandle'></div>" +
                     "    <div class='FloatingBoxInner'>" +
                     innerContent + "</div>" +
                     "</div></div>";

    $('FloatBoxWrapper').innerHTML = boxContent;
    $(innerDivID).set('opacity', 0);
    $('FloatBoxWrapper').style.display = 'block';
    $(innerDivID).set('opacity', 1);

    handle = $('FloatBoxHandle');
    new Drag.Move(innerDivID, {handle: 'FloatBoxHandle'});
    myWin = innerDivID;
}

function removeFloatingBox(){

    //alert("in removeFloatingBox");
    if(myWin){
        $(myWin).set('opacity', 0);
        $('FloatBoxWrapper').innerHTML = '';
        $('FloatBoxWrapper').className = '';
        $('FloatBoxWrapper').style.display = 'none';
        myWin = null;
    }

    removeEditor("Edit");
}

function submitEditListItem(theForm){

    //alert("in submitEditListItem");
    saveEditorContent("Edit");
    listItem["Link"] = 0;
    listItem["Description"] = 0;
    listItem["Extra"] = 0;
    descriptionContents["Edit"] = "";
    processForm(theForm, "List");
    removeFloatingBox();
    
    
}
function cancelEditListItem(){
    removeFloatingBox();

    listItem["Link"] = 0;
    listItem["Description"] = 0;
    listItem["Extra"] = 0;
}

function getStatusOptions(status){
    var options = "<select name='ListItem.ListItemStatusID' id='ListItemStatusID' class='SelectInput'>";
    if(status == 1){
        options = options + "<option value=''>Select</options>";
    }

    for (var id in StatusSetSelect) {
        if(!isNaN(id)){
            if(id == status){
                options  = options + "   <option value='" + id + "' selected>" + StatusSetSelect[id] + "</option>";
            }else{
                options  = options + "   <option value='" + id + "'>" + StatusSetSelect[id] + "</option>";
            }
        }
    }
    options  = options + "</select>";
    return options;
}

function changeClass(className, elem){
    elem.className = className;
}

function showLoginForm(callerID){
    removeFloatingBox();

    $('loginwrapper').fade('in');

};

function hideLogin(){
    var url = window.location;
    
    var re = /login/;
    if(! re.test(window.location)){
        $('loginwrapper').fade('out');
    }else{
        window.location = scriptsURL;
    }
};
function showTip(callerID, divID){
    removeFloatingBox();

    var tipContent = document.getElementById(divID).innerHTML;

    showFloatingBox(tipContent, "PopUpTip");
};


function submitSearch(){
    document.getElementById('searchForm').submit();
};

function searchForm(){
    if(document.getElementById('query').value != ''){
        return true;
    }else{
        return false;
    }
};


function setAddListItemFormElement(action, element){
    //alert("in setAddListItemFormElement " + action + ", " + element + ", " + listItem[element]);

    var content = "";
    switch (element){
        case "Link":
            if(! listItem["Link"]){
                content = "<div id='" + action + "LinkDiv' class='ListItemElement'><div class='ListItemExtraLabel'>Link:</div>" +
                          "<a class='DeleteSlider' alt='Remove' title='Remove' href='javascript:removeListItemExtra(\"" + action + "\", \"Link\")'></a><br />" +
                          "<input type='text' maxlength='200' value='http://' name='ListItem.Link' id='" + action + "ListItemLink' /></div>";
                listItem["Link"] = 1;
            }
            break;
        case "Description":
            if(! listItem["Description"]){
                content = "<div id='" + action + "DescriptionDiv'><div class='ListItemExtraLabel'>Description:</div>" +
                          "<a class='DeleteSlider' alt='Remove' title='Remove' href='javascript:removeListItemExtra(\"" + action + "\", \"Description\")'></a><br />" +
                          "<div id='" + action + "Editor'></div></div>";
                listItem["Description"] = 1;
            }
            break;
        case "Em":
            if(! listItem["Extra"]){
                content = "<div id='" + action + "EmDiv' class='ListItemElement'><div class='ListItemExtraLabel'>Embed code:</div>" + 
                          "<a class='DeleteSlider' alt='Remove' title='Remove' href='javascript:removeListItemExtra(\"" + action + "\", \"Em\")'></a><br />" +
                          "<textarea name='ListItem.Embed' id='" + action + "EmbedCode'></textarea></div>";
                listItem["Extra"] = 1;
            }
            break;
        default : 
            alert("Wha?");
            content = "Wha?";
    }

    
    if(listItem["Description"] == 1){
        var linkValue = "";
        if(listItem["Link"] == 1){
            linkValue = $(action + "ListItemLink").value;
        }

        removeEditor(action);
        var divToPutItIn = action + 'ListItemFormAdditions';
        $(divToPutItIn).innerHTML += content; 

        createEditor(action);

        if(linkValue != ""){
            $(action + "ListItemLink").value = linkValue;
        }
    }else{
        var divToPutItIn = action + 'ListItemFormAdditions';
        $(divToPutItIn).innerHTML += content; 
    }   

    if(element == "Link"){
        $(action + "ListItemLink").focus();
        $(action + "ListItemLink").select();
    }else if(element == "Em"){
        $(action + "EmbedCode").focus();
    }
}

function createEditor(action){

    //alert("in createEditor with action " + action);
	if ( ckeditors[action] ){
        return;
    }

    var height = "130px";
    if(action == "Edit"){
        height = "100px"
    }

	// Create a new editor inside the <div id=action + "Editor">
	ckeditors[action] = CKEDITOR.replace( action + 'Editor',    
    {
        uiColor: ThemeColor3,
        resize_enabled: false,
        toolbarCanCollapse: false,
        width: "292px",
        height: height,
        themeid: themeID,
        toolbar :
        [
            [ 'Bold','Italic','Underline','Strike','-','Subscript','Superscript', '-', 
              'NumberedList', 'BulletedList', '-', 'lclink', '-',
              'TextColor', 'SpecialChar', '-', 'Undo','Redo', '-', 'Source' ]
        ]
    });
    if($(action + 'Editor').innerHTML){
        descriptionContents[action] = $(action + 'Editor').innerHTML;
    }
	ckeditors[action].setData( descriptionContents[action]);
}

function saveEditorContent(action){
    //alert("in saveEditorContent with action " + action);

    if(! ckeditors[action]){
        return;
    }

    var DescriptionHiddenField = action + 'ListItemHiddenDescription';
    if($(DescriptionHiddenField) == null){
        // Means the form was removed, turn off the timer
        removeEditor(action);
    }else{
        descriptionContents[action] = ckeditors[action].getData();
        $(DescriptionHiddenField).value = descriptionContents[action];
    }
}

function removeEditor(action){

    //alert("in removeEditor with action: " + action);
	if ( !ckeditors[action] )
		return;

    try{
        ckeditors[action].destroy(true);
    }catch(err){
        // Only in IE is there an error -> Catch and ignore so it doesn't break the request
    }
    

	ckeditors[action] = null;
    listItem["Description"] = 0;
    var DescriptionHiddenField = action + 'ListItemHiddenDescription';

    if($(DescriptionHiddenField) != null){
        $(DescriptionHiddenField).value = "";
    }    
    if($(action + 'Editor') != null){
        $(action + 'Editor').innerHTML = "";
    }
    descriptionContents[action] = "";
}

function chooseAmazon(theForm, action){

    //alert("choosing amazon link! " + theForm.name + ", action: " + action);
    
    var ASIN; var imageSrc; var link;
    for(var i = 0; i < theForm.elements.length; i++){
        //alert("form: " + theForm.elements[i].name + ", value: " +
        //       theForm.elements[i].value +
        //     ", checked:" + theForm.elements[i].checked);

        if(theForm.elements[i].checked){
            
            ASIN = theForm.elements[i].value;
            //alert("checked: " + ASIN);
            if(ASIN){
                imageSrc = document.getElementById(ASIN + "Image").src;
                link = document.getElementById(ASIN + "Link").href;
            }
        }
    }

    if(! ASIN){
        alert("Please choose your Amazon image by clicking on the corresponding radio button");
    }else{

        top.document.getElementById(action + 'ExtraImage').src = imageSrc;
        top.document.getElementById(action + 'ExtraLink').href = link;
        top.document.getElementById(action + 'ExtraImageDiv').style.display = 'block';
        top.document.getElementById(action + 'ListItemASIN').value = ASIN;
    
        top.document.getElementById(action + 'RemoveExtraLink').href = "javascript:removeListItemExtra('" + action + "', 'Amazon')";
        top.document.getElementById(action + 'ExtraLabel').innerHTML = "Amazon image & link:";
        
        // Disable button
        top.disableListItemButton(action, "Amazon");
        
        if(action == "Add"){   
            top.AddAmazonMultibox.close();
        }else{
            top.EditAmazonMultibox.close();
        }        
    }
}


function chooseCCImage(theForm, action){

    //alert("choosing ccimage! " + theForm + ", action: " + action);

    var ID; var imageSrc; var link;
    for(var i = 0; i < theForm.elements.length; i++){
        //alert("form: " + theForm.elements[i].name + ", value: " +
        //       theForm.elements[i].value +
        //     ", checked:" + theForm.elements[i].checked);

        if(theForm.elements[i].checked){
            
            ID = theForm.elements[i].value;
            //alert("checked: " + ID);
            if(ID){
                imageSrc = document.getElementById(ID + "Image").src;
                link = document.getElementById(ID + "Link").href;
            }
        }
    }

    if(! ID){
        alert("Please choose your Creative Commons image by clicking on the corresponding radio button");
    }else{
        top.document.getElementById(action + 'ExtraImage').src = imageSrc;
        top.document.getElementById(action + 'ExtraLink').href = link;
        top.document.getElementById(action + 'ExtraImageDiv').style.display = 'block';
        top.document.getElementById(action + 'ListItemCCImage').value = ID;
    
        top.document.getElementById(action + 'RemoveExtraLink').href = "javascript:removeListItemExtra('" + action + "', 'CCImage')";
        top.document.getElementById(action + 'ExtraLabel').innerHTML = "Creative Commons image:";
    
        // Disable button
        top.disableListItemButton(action, "CCImage");

        if(action == "Add"){   
            top.AddCCImageMultibox.close();
        }else{
            top.EditCCImageMultibox.close();
        }
    }
}

function imageUploaded(ImageID, ImageSRC, action){

    if(action == "avatar"){
        window.opener.document.getElementById('UseAvatar2').checked = true;

        if(window.opener.document.getElementById('AvatarImage').src != ""){
            window.opener.document.getElementById('UploadedImageID').value = ImageID;
            window.opener.document.getElementById('AvatarImage').src = ImageSRC;
            window.opener.document.getElementById('AvatarImageImage').style.display = 'block';
            //window.opener.document.getElementById('AvatarImageImage').style.display = 'none';
        } 
   }else{
        window.opener.document.getElementById(action + 'ExtraImage').src = ImageSRC;
        window.opener.document.getElementById(action + 'ExtraLink').href = "#";
        window.opener.document.getElementById(action + 'ExtraImageDiv').style.display = 'block';
        window.opener.document.getElementById(action + 'ListItemImageID').value = ImageID;
    
        window.opener.document.getElementById(action + 'RemoveExtraLink').href = "javascript:removeListItemExtra('" + action + "', 'Image')";
        window.opener.document.getElementById(action + 'ExtraLabel').innerHTML = "Image:";
    
        disableListItemButton(action, 'Image');  
   }
}

function removeListItemExtra(action, element){

    //alert("in removeListItemExtra with " + action + ", " + element); 

    if(element == "Amazon" || element == "CCImage" || element == "Image"){
        document.getElementById(action + 'ExtraImage').src = "";
        document.getElementById(action + 'ExtraLink').href = "";
        document.getElementById(action + 'ExtraImageDiv').style.display = 'none';
        document.getElementById(action + 'ListItemASIN').value = "";
        document.getElementById(action + 'ListItemCCImage').value = "";
        document.getElementById(action + 'ListItemImageID').value = "";
    
        document.getElementById(action + 'RemoveExtraLink').href = "";
        document.getElementById(action + 'ExtraLabel').innerHTML = "";
    }else{

        if(element == "Description"){
            removeEditor(action);
            var DescriptionHiddenField = action + 'ListItemHiddenDescription';
            document.getElementById(DescriptionHiddenField).value = "";
        }

        var divToDelete = action + element + "Div";

        var div = document.getElementById(divToDelete);
        div.innerHTML = "";
        div.parentNode.removeChild(div);

        if(element == "Link" || element == "Description"){
            listItem[element] = 0;
        }else{
            listItem["Extra"] = 0;
        }
    }    

    enableListItemButton(action, element);
}

function disableListItemButton(action, element){
    // This function cannot use the $() syntax as I've elcted to not load the mootools
    // coode in the multiboxes to save some bytes

   //alert("in disableListItemButton with " + action + ", " + element);

    var ButtonID = action + element + "Button";

    if(element!== "Image"){
        if($(ButtonID).className  == "inactive"){
            // Its already disabled
            return;
        }
    }

    // Dull out button
    if(element == "Link" || element == "Description"){

        var theButton = $(ButtonID);
        theButton.className = "inactive";
        $(theButton).removeEvents('click');

    }else if(element == "Image"){

        if(window.opener.document.getElementById(ButtonID).className  == "inactive"){
            // Its already disabled
            return;
        }

        // This is executed from the pop up upload image window
        var Extras = new Array("Amazon", "Image", "CCImage", "Em");
        for(var i = 0; i < Extras.length; i++){

            var el = Extras[i];
            var theButton = action + el + "Button";
            window.opener.document.getElementById(theButton).className = "inactive"; 
            window.opener.document.getElementById(theButton).removeEvents('click');
        }
    }else{
        // It is one of the extras, so we have to disable them all
        var Extras = new Array("Amazon", "Image", "CCImage", "Em");
        for(var i = 0; i < Extras.length; i++){
            var el = Extras[i];
            var theButton = action + el + "Button";
            $(theButton).className = "inactive"; 
            $(theButton).removeEvents('click');
        }

        if(action == "Add"){   
            AddAmazonMultibox.turnOff();
            $('AddAmazonLink').href = "#";
            AddCCImageMultibox.turnOff();
            $('AddCCImageLink').href = "#";
        }else{
            EditAmazonMultibox.turnOff();
            $('AddAmazonLink').href = "#";
            EditCCImageMultibox.turnOff();
            $('AddCCImageLink').href = "#";
        }

        amazonMultibox = null;
        ccImageMultibox = null;
    }
}

function enableListItemButton(action, element){
    //alert("in enableListItemButton with " + element);

    var ButtonID = action + element + "Button";
    if(! $(ButtonID).className == "active"){
        // Its already enabled
        return;
    }

    // UnDull out button
    if(element == "Link" || element == "Description"){

        $(ButtonID).className = "active";     

        $(ButtonID).addEvent('click', function(e){
            e.stop();
            setAddListItemFormElement(action, element);
            disableListItemButton(action, element);
        });
    }else{
        // It is one of the extras, so we have to disable them all
        var Extras = new Array("Amazon", "Image", "CCImage", "Em");
        for(var i = 0; i < Extras.length; i++){
            var el = Extras[i]; 
            var ButtonID = action + el + "Button";

            $(ButtonID).className = "active"; 
            $(ButtonID).removeEvents('click');
        }       

        // Clear the hidden fields
        $(action + "ListItemASIN").value = "";
        $(action + "ListItemCCImage").value = "";
        $(action + "ListItemImageID").value = "";
        // Put the actions back on the buttons
        var emButton = action + 'EmButton';
        $(emButton).addEvent('click', function(e){
            e.stop();
            
            setAddListItemFormElement(action, 'Em');
            disableListItemButton(action, 'Em');
        });

        var imageButton = action + 'ImageButton';
        $(imageButton).addEvent('click', function(e){
            e.stop();
            openWindow('upload_image.html?action=' + action, 'UploadImage','height=486,width=430,status=yes,toolbar=no,scrollbars=yes');
        });

        if(action == "Add"){   
            AddAmazonMultibox.turnOn();
            $('AddAmazonLink').href = "/Utilities/Amazon/send_request.html?ajax=1&action=Add";

            AddCCImageMultibox.turnOn();
            $('AddCCImageLink').href = "/Utilities/CCImage/send_request.html?ajax=1&action=Add";
        }else{
            EditAmazonMultibox.turnOn();
            $('EditAmazonLink').href = "/Utilities/Amazon/send_request.html?ajax=1&action=Edit";

            EditCCImageMultibox.turnOn();
            $('EditCCImageLink').href = "/Utilities/CCImage/send_request.html?ajax=1&action=Edit";
        }        
    }
}

function setSliderContent(withWhat){

    var sliders = new Array("AddListItemContent", "CommentsContent", "TagsContent", "EmailContent", "EditListContent");
    for(var i = 0; i < sliders.length; i++){
        if($(sliders[i]) != null){
            $(sliders[i]).style.display = 'none';
        }
    }
    
    $(withWhat).style.display = 'block';
}

var whichTab = "";
function doSlider(e, formSlide, which){

    if(e != ""){
        e.stop();
    }

    //alert("Slider open? " + formSlide.open +", which? " + which);
    // Close slider if open
    if(formSlide.open == true){

        // Just close the tab
        if(which == whichTab){
            formSlide.slideOut();
            return;
        }else{
            formSlide.hide();
        }
    }

    //while(formSlide.open == false){}
    setSliderContent(which);
    whichTab = which;

    // Open slider
    formSlide.slideIn();

    
}


/////////////////////////// Shortcut /////////////////////////////

var shortcut = {
	'all_shortcuts':{},//All the shortcuts are stored in this array
	'add': function(shortcut_combination,callback,opt) {
		//Provide a set of default options
		var default_options = {
			'type':'keydown',
			'propagate':false,
			'disable_in_input':false,
			'target':document,
			'keycode':false
		}
		if(!opt) opt = default_options;
		else {
			for(var dfo in default_options) {
				if(typeof opt[dfo] == 'undefined') opt[dfo] = default_options[dfo];
			}
		}

		var ele = opt.target;
		if(typeof opt.target == 'string') ele = document.getElementById(opt.target);
		var ths = this;
		shortcut_combination = shortcut_combination.toLowerCase();

		//The function to be called at keypress
		var func = function(e) {
			e = e || window.event;
			
			if(opt['disable_in_input']) { //Don't enable shortcut keys in Input, Textarea fields
				var element;
				if(e.target) element=e.target;
				else if(e.srcElement) element=e.srcElement;
				if(element.nodeType==3) element=element.parentNode;

				if(element.tagName == 'INPUT' || element.tagName == 'TEXTAREA') return;
			}
	
			//Find Which key is pressed
			if (e.keyCode) code = e.keyCode;
			else if (e.which) code = e.which;
			var character = String.fromCharCode(code).toLowerCase();
			
			if(code == 188) character=","; //If the user presses , when the type is onkeydown
			if(code == 190) character="."; //If the user presses , when the type is onkeydown

			var keys = shortcut_combination.split("+");
			//Key Pressed - counts the number of valid keypresses - if it is same as the number of keys, the shortcut function is invoked
			var kp = 0;
			
			//Work around for stupid Shift key bug created by using lowercase - as a result the shift+num combination was broken
			var shift_nums = {
				"`":"~",
				"1":"!",
				"2":"@",
				"3":"#",
				"4":"$",
				"5":"%",
				"6":"^",
				"7":"&",
				"8":"*",
				"9":"(",
				"0":")",
				"-":"_",
				"=":"+",
				";":":",
				"'":"\"",
				",":"<",
				".":">",
				"/":"?",
				"\\":"|"
			}
			//Special Keys - and their codes
			var special_keys = {
				'esc':27,
				'escape':27,
				'tab':9,
				'space':32,
				'return':13,
				'enter':13,
				'backspace':8,	
				'scrolllock':145,
				'scroll_lock':145,
				'scroll':145,
				'capslock':20,
				'caps_lock':20,
				'caps':20,
				'numlock':144,
				'num_lock':144,
				'num':144,				
				'pause':19,
				'break':19,				
				'insert':45,
				'home':36,
				'delete':46,
				'end':35,				
				'pageup':33,
				'page_up':33,
				'pu':33,	
				'pagedown':34,
				'page_down':34,
				'pd':34,	
				'left':37,
				'up':38,
				'right':39,
				'down':40,	
				'f1':112,
				'f2':113,
				'f3':114,
				'f4':115,
				'f5':116,
				'f6':117,
				'f7':118,
				'f8':119,
				'f9':120,
				'f10':121,
				'f11':122,
				'f12':123
			}
	
			var modifiers = { 
				shift: { wanted:false, pressed:false},
				ctrl : { wanted:false, pressed:false},
				alt  : { wanted:false, pressed:false},
				meta : { wanted:false, pressed:false}	//Meta is Mac specific
			};
                        
			if(e.ctrlKey)	modifiers.ctrl.pressed = true;
			if(e.shiftKey)	modifiers.shift.pressed = true;
			if(e.altKey)	modifiers.alt.pressed = true;
			if(e.metaKey)   modifiers.meta.pressed = true;
                        
			for(var i=0; k=keys[i],i<keys.length; i++) {
				//Modifiers
				if(k == 'ctrl' || k == 'control') {
					kp++;
					modifiers.ctrl.wanted = true;

				} else if(k == 'shift') {
					kp++;
					modifiers.shift.wanted = true;

				} else if(k == 'alt') {
					kp++;
					modifiers.alt.wanted = true;
				} else if(k == 'meta') {
					kp++;
					modifiers.meta.wanted = true;
				} else if(k.length > 1) { //If it is a special key
					if(special_keys[k] == code) kp++;
					
				} else if(opt['keycode']) {
					if(opt['keycode'] == code) kp++;

				} else { //The special keys did not match
					if(character == k) kp++;
					else {
						if(shift_nums[character] && e.shiftKey) { //Stupid Shift key bug created by using lowercase
							character = shift_nums[character]; 
							if(character == k) kp++;
						}
					}
				}
			}
			
			if(kp == keys.length && 
						modifiers.ctrl.pressed == modifiers.ctrl.wanted &&
						modifiers.shift.pressed == modifiers.shift.wanted &&
						modifiers.alt.pressed == modifiers.alt.wanted &&
						modifiers.meta.pressed == modifiers.meta.wanted) {
				callback(e);
	
				if(!opt['propagate']) { //Stop the event
					//e.cancelBubble is supported by IE - this will kill the bubbling process.
					e.cancelBubble = true;
					e.returnValue = false;
	
					//e.stopPropagation works in Firefox.
					if (e.stopPropagation) {
						e.stopPropagation();
						e.preventDefault();
					}
					return false;
				}
			}
		}
		this.all_shortcuts[shortcut_combination] = {
			'callback':func, 
			'target':ele, 
			'event': opt['type']
		};
		//Attach the function with the event
		if(ele.addEventListener) ele.addEventListener(opt['type'], func, false);
		else if(ele.attachEvent) ele.attachEvent('on'+opt['type'], func);
		else ele['on'+opt['type']] = func;
	},

	//Remove the shortcut - just specify the shortcut and I will remove the binding
	'remove':function(shortcut_combination) {
		shortcut_combination = shortcut_combination.toLowerCase();
		var binding = this.all_shortcuts[shortcut_combination];
		delete(this.all_shortcuts[shortcut_combination])
		if(!binding) return;
		var type = binding['event'];
		var ele = binding['target'];
		var callback = binding['callback'];

		if(ele.detachEvent) ele.detachEvent('on'+type, callback);
		else if(ele.removeEventListener) ele.removeEventListener(type, callback, false);
		else ele['on'+type] = false;
	}
}

var scriptsURL = "";

/////////////////////////////////////////////// Edit in Place ///////////////////////////////////////////////////////////
//
//   1. Highlight the area onMouseOver
//   2. Clear the highlight onMouseOut
//   3. If the user clicks, hide the area and replace with a <textarea> and buttons
//   4. Remove all of the above if the user cancels the operation by pressing escape
//   5. When the user indicates "save", by typing enter, make an Ajax POST and show that something.s happening
//   6. When the Ajax call comes back, update the page with the new content
function showAsEditable(divID, mouseout){
    if (!mouseout){
        document.getElementById(divID).className = "editable";
    }else{
        document.getElementById(divID).className = "noneditable";
    }
}

var elemSave = new Array();
function edit(divID, elem, lines){
    var text = elem.innerHTML;

    elemSave[elem.id] = new Array();
    elemSave[elem.id]['tag'] = elem.nodeName; 
    elemSave[elem.id]['id'] = elem.id; 
    elemSave[elem.id]['text'] = text;

    var onkeypressFunction = "onkeyup=\"checkSave(event, '" + divID + "', '" + elem.id + "')\"";

    var saveButton = "<img class=\"cancelSaveButton\" src=\"/images/icons/save.png\" alt=\"Save\" title=\"Save\" onclick=\"saveChanges('" + divID + "')\" />";
    var cancelButton = "<img class=\"cancelSaveButton\" src=\"/images/icons/cancel.png\" alt=\"Cancel\" title=\"Cancel\" onclick=\"cancelChanges('" + divID + "', '" + elem.id + "')\" />";

    var input;
    if(lines == 1){
        var textinput = "<input id=\"" + divID + "_editor\" name=\"" + divID + "\"" + onkeypressFunction + 
                        " class=\"EditingTextInput\" value=\"" + text + "\" maxlength=\"100\" /><br />" + 
            saveButton + cancelButton;
        input = textinput;
    }else if(lines == 3){
        // Turn the br's into new lines
        text = text.replace(/<br>/gi, "\n");
        var textarea = "<textarea id=\"" + divID + "_editor\" name=\"" + divID + "\" " + 
            onkeypressFunction + " class=\"EditingListItemTextarea\" onkeypress=\"return imposeMaxLength(event, this, 200);\">" +text+ "</textarea><br />" + 
            saveButton + cancelButton;
        input = textarea;
    }else if(lines == 5){
        // Turn the br's into new lines
        text = text.replace(/<br>/gi, "\n");
        var textarea = "<textarea id=\"" + divID + "_editor\" name=\"" + divID + "\" " + 
            onkeypressFunction + " class=\"EditingDescriptionTextarea\" >" +text+ "</textarea><br />" + 
            saveButton + cancelButton;
        input = textarea;
    }  

    document.getElementById(divID).innerHTML = input;
    document.getElementById(divID).className = "editing";
    document.getElementById(divID + "_editor").focus();

    shortcut.add("Ctrl+Alt+S",function() { saveChanges(divID); },{
        	'type':'keydown',
        	'propagate':false,
        	'target':document
        });

}

function checkSave(event, divID, id){
    //alert("in here! " + event.keyCode + ", " + event.which + ", divID: " + divID);
    if(divID != undefined){
        var key = event.keyCode ? event.keyCode : event.which;
        if(key == 27){
            // Esc means cancel changes
            cancelChanges(divID, id);
        }else{
            //alert("key: " + key);
        }
    }
}

function saveChanges(divID){
    //divID = divIDSave;

    if(divID != undefined){
        // Send the request back to the server
        var textArea = divID + "_editor";
        var newText = document.getElementById(textArea).value;

        // Parse the divID to determine the table we are dealing with and the ID
        var ID; var field = "Name";
        var table = "ListItem";
        if(divID.substr(0, 9) == "ListGroup"){
            table = "ListGroup";
            var splitArray = divID.split('p');
            ID = splitArray[1];
        }else if(divID.substr(0, 9) == "StatusSet"){
            table = "StatusSet";
            var splitArray = divID.split('et');
            ID = splitArray[1];
        }else{
            var splitArray = divID.split('m');
            ID = splitArray[1];
            var re = /Description/;
            if (re.test(ID)) { 
                field = "Description";
                splitArray = ID.split('D');
                ID = splitArray[0];
            }            
        }

        newText = encodeURIComponent(newText);
        var url = scriptsURL + "?Table=" + table + "&ID=" + ID + "&Field=" + field + 
                  "&todo=editInPlace&ajax=1&Value=" + newText;
        spinner = "/images/" + themeID + "/horizontal_spinner.gif"

        if(divID.substr(0, 5) == "ListI"){
            document.getElementById(divID).style.width = "100%";
        }
        document.getElementById(divID).className = "noneditable";

        shortcut.remove("Ctrl+Alt+S");
        listChanged = 1;
        
        doServerRequest(url, divID);
    }
}

function replaceAll(srcStr, dstStr, Str) {
    var pat = new RegExp(srcStr, "g");
    var newStr = Str.replace(this.pat, dstStr);
    return newStr;
}


function cancelChanges(divID, id){
    if(divID != undefined){

        //alert("in cancelChanges with id: " + id);
        var lines = 1;
        var regex = new RegExp('Description', 'im');
        if(divID.match(regex)){
            lines = 5;
        }else{
            var regex = new RegExp('ListItem', 'im');
            if(divID.match(regex)){
                lines = 3;
            }
        }              

        var theid = "id=\"" + id + "\"";
        var onmouseoutFunction = "onmouseout=\"showAsEditable('" + divID + "', true)\"";
        var onmouseoverFunction = "onmouseover=\"showAsEditable('" + divID + "', false)\"";
        var onclickFunction = "onclick=\"edit('" + divID + "', this, " + lines + ")\"";

        $(divID).innerHTML = "<" + elemSave[id]['tag'] + " " + 
                              theid + " " + onmouseoutFunction +  " " + onmouseoverFunction + " " +
                              onclickFunction + ">" + 
                              elemSave[id]['text'] + 
                              "</" + elemSave[id]['tag'] + ">";
        
        $(divID).className = "noneditable";
    }
}

function doServerRequest(theURL, DivID){

    //alert("in doServerRequest with " + theURL + ", " + DivID);
    var splitArray = theURL.split('?');
    var URL = splitArray[0];
    var params = splitArray[1];
    
    var request = new Request.HTML({
			method: 'get',
			url: URL,
			onRequest: function() { getLoadingContent(DivID); },
			update: $(DivID),
            noCache: true
		});
    request.send(params);
}

function doServerRequestWithFunc(theURL, DivID, func){

    //alert("in doServerRequestWithFunc with: " + theURL);
    var splitArray = theURL.split('?');
    var URL = splitArray[0];
    var params = splitArray[1];
    
    var request = new Request.HTML({
			method: 'post',
			url: URL,
			onRequest: function() { getLoadingContent(DivID); },
            onComplete: function() { func(); },
			update: $(DivID)
		});
    request.send(params);
}

function getLoadingContent(DivID){

    //alert("in getLoadingContent: " + DivID);
    var spinnerContent;
    if(DivID != ""){
        spinnerContent = getSpinnerContent(DivID, spinner);
        
        var elems = document.getElementById(DivID);
        elems.style.display = '';        
        elems.innerHTML = spinnerContent;
    }
    //return spinnerContent;
}

function getSpinnerContent(DivID){

    var spinnerContent = "";
    var re = /horizontal_spinner/;
    var reMore = /More/;

    if(DivID == "List"){
        spinnerContent = "<center><div class='LoadingBig'>" +
                         "   <img src='/images/" + themeID + "/lclogo.png' class='LoadingLogo' alt='List Central' />" +
                         "   <p>Loading...</p>" +
                         "   <img src='/images/" + themeID + "/ajax-loader.gif' class='AjaxLoader' alt='' />" +
                         "</div></center>";
    }else if(re.test(spinner)){
        spinnerContent = "<div class='TightSpinner'><img src='" + spinner + "' alt='Please wait...' /></div>";
    }else{
        spinnerContent = "<center><div class='Loading'>" +
                         "   <img src='/images/" + themeID + "/lclogo.png' class='LoadingLogo' alt='List Central' />" +
                         "   <p>Loading...</p>" +
                         "   <img src='/images/" + themeID + "/ajax-loader.gif' class='AjaxLoader' alt='' />" +
                         "</div></center>";

    }

    spinner = "";
    return spinnerContent;
}

                       
//////////////////////////////////////////////////////
//
// Show hide pop over divs
// 

var PopOver = 0;

function showPopOver(divID) {
    if(PopOver == 0){
        var div = document.getElementById(divID);
        div.style.display = '';  
        PopOver = 1;
    }   
}

function hidePopOver(divID) {
    document.getElementById(divID).style.display = 'none';  
    PopOver = 0;
}

                       
//////////////////////////////////////////////////////
//
//  Other stuff
// 
function closeWindow_ParentReload(){
    window.opener.location.reload(true);
    self.close();
}

function openWindow(theURL,winName,features) { 
  window.open(theURL,winName,features);
}

function closeWindow (){
    self.close();
}

function setSearchValues(){
    document.getElementById('query').value = "Search...";
}

function clearSearchInput(isfocus){
    if(isfocus == 1){
        document.getElementById('query').value = "";
    }else if(document.getElementById('query').value == ""){
        document.getElementById('query').value = "Search...";
    }
}

function clearBoardMessage(){
    boardmessage = document.getElementById("BoardMessageInput");
    if(boardmessage.value == "Write Something..."){
        boardmessage.value = "";
    }else if(boardmessage.value == ""){
        boardmessage.value = "Write Something...";
    }
};
function setBoardMessage(){
    document.getElementById("BoardMessageInput").value = "Write Something...";
};
var notRequired = new Object();
function validateForm(theForm){
    var valid = false;
    var showHumanCheck = false;
    for (var i=0; i < theForm.elements.length; i++) {
        var theInput = theForm.elements[i];
        if(theInput.name == "Human"){
            showHumanCheck = true;
        }else{
            if(!notRequired[theInput.name]){ 
                if(theInput.type == "select-one" || theInput.type == "select-multiple"){
                    if(!theInput.options[theInput.selectedIndex].value == ""){
                        valid = true;
                    }
                }else if (theInput.type == "text" || theInput.type == "password") {
                    if(theInput.value != ""){
                        valid = true;
                    }
                }else if (theInput.type == "hidden") {
                    valid = true;
                }
            }
        }
    }

    if(showHumanCheck){
        var answer = prompt("Are you human? Please type 'yes' below and click ok").toLowerCase();
        if(answer == "yes"){
            document.getElementById("Human").value = 1;
        }
    }

    return valid;
}

function validateSignUp(theForm){

    if(document.getElementById("PasswordSignup").value != document.getElementById("PasswordConfirm").value){
        alert("Passwords do not match");
        document.getElementById("PasswordSignup").focus();
        return false;
    }

    if(document.getElementById("Email").value == ""){
        alert("Email is blank");
        document.getElementById("Email").focus();
        return false;
    }
    if(document.getElementById("UsernameSignup").value == ""){
        alert("Username is blank");
        document.getElementById("UsernameSignup").focus();
        return false;
    }
    if(document.getElementById("PasswordSignup").value == ""){
        alert("Password is blank");
        document.getElementById("PasswordSignup").focus();
        return false;
    }

    return true;
}


function checkobject(obj) {
    return true;
    if (document.getElementById(obj)) { 
        return true; 
    } else { 
        return false; 
    }
}

function setThemeVisuals(ThemeID){
    var thisThemeColours = themeColours[ThemeID];

    var html = "";
    for (var i = 0; i < thisThemeColours.length; i++) {
        html = html + "<div class='themeColourVisual' style='background:" + thisThemeColours[i] + "'>&nbsp;</div>";
    }
    document.getElementById('ThemeVisualization').innerHTML = html;
}

function wait(){
    var date = new Date();
    var curDate = null;

    var millis = 2000;
    
    do { curDate = new Date(); }
    while(curDate-date < millis);
}

function imposeMaxLength(event, object, MaxLen){   

    var key = event.keyCode ? event.keyCode : event.which;
    if(key == 8){
        return true;
    }else{
        return (object.value.length <= MaxLen);
    }  
}

function confirmDeactivate(){
    var confirmed = confirm('Are you sure you want to deactivate you account?')

    document.getElementById('PasswordVerifyHidden').value = document.getElementById('PasswordVerify').value;

    return confirmed;
}

function pause(millis){
    var date = new Date();
    var curDate = null;
    
    do { curDate = new Date(); }
    while(curDate-date < millis);
} 



//-->
