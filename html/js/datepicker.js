var DatePicker=new Class({Implements:Options,d:"",today:"",choice:{},bodysize:{},limit:{},attachTo:null,picker:null,slider:null,oldContents:null,newContents:null,input:null,visual:null,options:{pickerClass:"datepicker",days:["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"],months:["January","February","March","April","May","June","July","August","September","October","November","December"],dayShort:2,monthShort:3,startDay:1,timePicker:false,timePickerOnly:false,yearPicker:true,yearsPerPage:20,format:"d-m-Y",allowEmpty:false,inputOutputFormat:"U",animationDuration:400,useFadeInOut:!Browser.Engine.trident,startView:"month",positionOffset:{x:0,y:0},minDate:null,maxDate:null,debug:false,toggleElements:null,onShow:$empty,onClose:$empty,onSelect:$empty},initialize:function(b,a){this.attachTo=b;this.setOptions(a).attach();if(this.options.timePickerOnly){this.options.timePicker=true;this.options.startView="time"}this.formatMinMaxDates();document.addEvent("mousedown",this.close.bind(this))},formatMinMaxDates:function(){if(this.options.minDate&&this.options.minDate.format){this.options.minDate=this.unformat(this.options.minDate.date,this.options.minDate.format)}if(this.options.maxDate&&this.options.maxDate.format){this.options.maxDate=this.unformat(this.options.maxDate.date,this.options.maxDate.format);this.options.maxDate.setHours(23);this.options.maxDate.setMinutes(59);this.options.maxDate.setSeconds(59)}},attach:function(){if($chk(this.options.toggleElements)){var a=$$(this.options.toggleElements);document.addEvents({keydown:function(b){if(b.key=="tab"){this.close(null,true)}}.bind(this)})}$$(this.attachTo).each(function(d,c){if(d.retrieve("datepicker")){return}var b;if($chk(d.get("value"))){b=this.format(new Date(this.unformat(d.get("value"),this.options.inputOutputFormat)),this.options.format)}else{if(!this.options.allowEmpty){b=this.format(new Date(),this.options.format)}else{b=""}}if(this.options.inputID){$(this.options.inputID).value=b}var e=d.getStyle("display");var f=d.setStyle("display",this.options.debug?e:"none").store("datepicker",true).clone().store("datepicker",true).removeProperty("name").setStyle("display",e).set("value",b).inject(d,"after");if($chk(this.options.toggleElements)){a[c].setStyle("cursor","pointer").addEvents({click:function(g){this.onFocus(d,f)}.bind(this)});f.addEvents({blur:function(){d.set("value",f.get("value"))}})}else{f.addEvents({keydown:function(g){if(this.options.allowEmpty&&(g.key=="delete"||g.key=="backspace")){d.set("value","");g.target.set("value","");this.close(null,true)}else{if(g.key=="tab"){this.close(null,true)}else{g.stop()}}}.bind(this),focus:function(g){this.onFocus(d,f)}.bind(this)})}}.bind(this))},onFocus:function(b,a){var c,e=a.getCoordinates();if($chk(b.get("value"))){c=this.unformat(b.get("value"),this.options.inputOutputFormat).valueOf()}else{c=new Date();if($chk(this.options.maxDate)&&c.valueOf()>this.options.maxDate.valueOf()){c=new Date(this.options.maxDate.valueOf())}if($chk(this.options.minDate)&&c.valueOf()<this.options.minDate.valueOf()){c=new Date(this.options.minDate.valueOf())}}this.show({left:e.left+this.options.positionOffset.x,top:e.top+e.height+this.options.positionOffset.y},c);this.input=b;this.visual=a;this.options.onShow()},dateToObject:function(a){return{year:a.getFullYear(),month:a.getMonth(),day:a.getDate(),hours:a.getHours(),minutes:a.getMinutes(),seconds:a.getSeconds()}},dateFromObject:function(a){var b=new Date();b.setDate(1);["year","month","day","hours","minutes","seconds"].each(function(d){var c=a[d];if(!$chk(c)){return}switch(d){case"day":b.setDate(c);break;case"month":b.setMonth(c);break;case"year":b.setFullYear(c);break;case"hours":b.setHours(c);break;case"minutes":b.setMinutes(c);break;case"seconds":b.setSeconds(c);break}});return b},show:function(a,b){this.formatMinMaxDates();if($chk(b)){this.d=new Date(b)}else{this.d=new Date()}this.today=new Date();this.choice=this.dateToObject(this.d);this.mode=(this.options.startView=="time"&&!this.options.timePicker)?"month":this.options.startView;this.render();this.picker.setStyles(a)},render:function(b){if(!$chk(this.picker)){this.constructPicker()}else{var c=this.oldContents;this.oldContents=this.newContents;this.newContents=c;this.newContents.empty()}var a=new Date(this.d.getTime());this.limit={right:false,left:false};if(this.mode=="decades"){this.renderDecades()}else{if(this.mode=="year"){this.renderYear()}else{if(this.mode=="time"){this.renderTime();this.limit={right:true,left:true}}else{this.renderMonth()}}}this.picker.getElement(".previous").setStyle("visibility",this.limit.left?"hidden":"visible");this.picker.getElement(".next").setStyle("visibility",this.limit.right?"hidden":"visible");this.picker.getElement(".titleText").setStyle("cursor",this.allowZoomOut()?"pointer":"default");this.d=a;if(this.picker.getStyle("opacity")==0){this.picker.tween("opacity",0,1)}if($chk(b)){this.fx(b)}},fx:function(a){if(a=="right"){this.oldContents.setStyles({left:0,opacity:1});this.newContents.setStyles({left:this.bodysize.x,opacity:1});this.slider.setStyle("left",0).tween("left",0,-this.bodysize.x)}else{if(a=="left"){this.oldContents.setStyles({left:this.bodysize.x,opacity:1});this.newContents.setStyles({left:0,opacity:1});this.slider.setStyle("left",-this.bodysize.x).tween("left",-this.bodysize.x,0)}else{if(a=="fade"){this.slider.setStyle("left",0);this.oldContents.setStyle("left",0).set("tween",{duration:this.options.animationDuration/2}).tween("opacity",1,0);this.newContents.setStyles({opacity:0,left:0}).set("tween",{duration:this.options.animationDuration}).tween("opacity",0,1)}}}},constructPicker:function(){this.picker=new Element("div",{"class":this.options.pickerClass}).inject(document.body);if(this.options.useFadeInOut){this.picker.setStyle("opacity",0).set("tween",{duration:this.options.animationDuration})}var d=new Element("div",{"class":"header"}).inject(this.picker);var c=new Element("div",{"class":"title"}).inject(d);new Element("div",{"class":"previous"}).addEvent("click",this.previous.bind(this)).set("text","?").inject(d);new Element("div",{"class":"next"}).addEvent("click",this.next.bind(this)).set("text","?").inject(d);new Element("div",{"class":"closeButton"}).addEvent("click",this.close.bindWithEvent(this,true)).set("text","x").inject(d);new Element("span",{"class":"titleText"}).addEvent("click",this.zoomOut.bind(this)).inject(c);var a=new Element("div",{"class":"body"}).inject(this.picker);this.bodysize=a.getSize();this.slider=new Element("div",{styles:{position:"absolute",top:0,left:0,width:2*this.bodysize.x,height:this.bodysize.y}}).set("tween",{duration:this.options.animationDuration,transition:Fx.Transitions.Quad.easeInOut}).inject(a);this.oldContents=new Element("div",{styles:{position:"absolute",top:0,left:this.bodysize.x,width:this.bodysize.x,height:this.bodysize.y}}).inject(this.slider);this.newContents=new Element("div",{styles:{position:"absolute",top:0,left:0,width:this.bodysize.x,height:this.bodysize.y}}).inject(this.slider)},renderTime:function(){var a=new Element("div",{"class":"time"}).inject(this.newContents);if(this.options.timePickerOnly){this.picker.getElement(".titleText").set("text","Select a time")}else{this.picker.getElement(".titleText").set("text",this.format(this.d,"j M, Y"))}new Element("input",{type:"text","class":"hour"}).set("value",this.leadZero(this.d.getHours())).addEvents({mousewheel:function(d){var c=d.target,b=c.get("value").toInt();c.focus();if(d.wheel>0){b=(b<23)?b+1:0}else{b=(b>0)?b-1:23}c.set("value",this.leadZero(b));d.stop()}.bind(this)}).set("maxlength",2).inject(a);new Element("input",{type:"text","class":"minutes"}).set("value",this.leadZero(this.d.getMinutes())).addEvents({mousewheel:function(d){var c=d.target,b=c.get("value").toInt();c.focus();if(d.wheel>0){b=(b<59)?b+1:0}else{b=(b>0)?b-1:59}c.set("value",this.leadZero(b));d.stop()}.bind(this)}).set("maxlength",2).inject(a);new Element("div",{"class":"separator"}).set("text",":").inject(a);new Element("input",{type:"submit",value:"OK","class":"ok"}).addEvents({click:function(b){b.stop();this.select($merge(this.dateToObject(this.d),{hours:this.picker.getElement(".hour").get("value").toInt(),minutes:this.picker.getElement(".minutes").get("value").toInt()}))}.bind(this)}).set("maxlength",2).inject(a)},renderMonth:function(){var h=this.d.getMonth();this.picker.getElement(".titleText").set("text",this.options.months[h]+" "+this.d.getFullYear());this.d.setDate(1);while(this.d.getDay()!=this.options.startDay){this.d.setDate(this.d.getDate()-1)}var a=new Element("div",{"class":"days"}).inject(this.newContents);var g=new Element("div",{"class":"titles"}).inject(a);var k,f,c,j,m;for(k=this.options.startDay;k<(this.options.startDay+7);k++){new Element("div",{"class":"title day day"+(k%7)}).set("text",this.options.days[(k%7)].substring(0,this.options.dayShort)).inject(g)}var b=false;var n=this.today.toDateString();var l=this.dateFromObject(this.choice).toDateString();for(f=0;f<42;f++){c=[];c.push("day");c.push("day"+this.d.getDay());if(this.d.toDateString()==n){c.push("today")}if(this.d.toDateString()==l){c.push("selected")}if(this.d.getMonth()!=h){c.push("otherMonth")}if(f%7==0){m=new Element("div",{"class":"week week"+(Math.floor(f/7))}).inject(a)}j=new Element("div",{"class":c.join(" ")}).set("text",this.d.getDate()).inject(m);if(this.limited("date")){j.addClass("unavailable");if(b){this.limit.right=true}else{if(this.d.getMonth()==h){this.limit.left=true}}}else{b=true;j.addEvent("click",function(i,o){if(this.options.timePicker){this.d.setDate(o.day);this.d.setMonth(o.month);this.mode="time";this.render("fade")}else{this.select(o)}}.bindWithEvent(this,{day:this.d.getDate(),month:this.d.getMonth(),year:this.d.getFullYear()}))}this.d.setDate(this.d.getDate()+1)}if(!b){this.limit.right=true}},renderYear:function(){var g=this.today.getMonth();var c=this.d.getFullYear()==this.today.getFullYear();var h=this.d.getFullYear()==this.choice.year;this.picker.getElement(".titleText").set("text",this.d.getFullYear());this.d.setMonth(0);var b,f;var d=false;var a=new Element("div",{"class":"months"}).inject(this.newContents);for(b=0;b<=11;b++){f=new Element("div",{"class":"month month"+(b+1)+(b==g&&c?" today":"")+(b==this.choice.month&&h?" selected":"")}).set("text",this.options.monthShort?this.options.months[b].substring(0,this.options.monthShort):this.options.months[b]).inject(a);if(this.limited("month")){f.addClass("unavailable");if(d){this.limit.right=true}else{this.limit.left=true}}else{d=true;f.addEvent("click",function(i,j){this.d.setDate(1);this.d.setMonth(j);this.mode="month";this.render("fade")}.bindWithEvent(this,b))}this.d.setMonth(b)}if(!d){this.limit.right=true}},renderDecades:function(){while(this.d.getFullYear()%this.options.yearsPerPage>0){this.d.setFullYear(this.d.getFullYear()-1)}this.picker.getElement(".titleText").set("text",this.d.getFullYear()+"-"+(this.d.getFullYear()+this.options.yearsPerPage-1));var b,f,d;var c=false;var a=new Element("div",{"class":"years"}).inject(this.newContents);if($chk(this.options.minDate)&&this.d.getFullYear()<=this.options.minDate.getFullYear()){this.limit.left=true}for(b=0;b<this.options.yearsPerPage;b++){f=this.d.getFullYear();d=new Element("div",{"class":"year year"+b+(f==this.today.getFullYear()?" today":"")+(f==this.choice.year?" selected":"")}).set("text",f).inject(a);if(this.limited("year")){d.addClass("unavailable");if(c){this.limit.right=true}else{this.limit.left=true}}else{c=true;d.addEvent("click",function(g,h){this.d.setFullYear(h);this.mode="year";this.render("fade")}.bindWithEvent(this,f))}this.d.setFullYear(this.d.getFullYear()+1)}if(!c){this.limit.right=true}if($chk(this.options.maxDate)&&this.d.getFullYear()>=this.options.maxDate.getFullYear()){this.limit.right=true}},limited:function(c){var b=$chk(this.options.minDate);var d=$chk(this.options.maxDate);if(!b&&!d){return false}switch(c){case"year":return(b&&this.d.getFullYear()<this.options.minDate.getFullYear())||(d&&this.d.getFullYear()>this.options.maxDate.getFullYear());case"month":var a=(""+this.d.getFullYear()+this.leadZero(this.d.getMonth())).toInt();return b&&a<(""+this.options.minDate.getFullYear()+this.leadZero(this.options.minDate.getMonth())).toInt()||d&&a>(""+this.options.maxDate.getFullYear()+this.leadZero(this.options.maxDate.getMonth())).toInt();case"date":return(b&&this.d<this.options.minDate)||(d&&this.d>this.options.maxDate)}},allowZoomOut:function(){if(this.mode=="time"&&this.options.timePickerOnly){return false}if(this.mode=="decades"){return false}if(this.mode=="year"&&!this.options.yearPicker){return false}return true},zoomOut:function(){if(!this.allowZoomOut()){return}if(this.mode=="year"){this.mode="decades"}else{if(this.mode=="time"){this.mode="month"}else{this.mode="year"}}this.render("fade")},previous:function(){if(this.mode=="decades"){this.d.setFullYear(this.d.getFullYear()-this.options.yearsPerPage)}else{if(this.mode=="year"){this.d.setFullYear(this.d.getFullYear()-1)}else{if(this.mode=="month"){this.d.setMonth(this.d.getMonth()-1)}}}this.render("left")},next:function(){if(this.mode=="decades"){this.d.setFullYear(this.d.getFullYear()+this.options.yearsPerPage)}else{if(this.mode=="year"){this.d.setFullYear(this.d.getFullYear()+1)}else{if(this.mode=="month"){this.d.setMonth(this.d.getMonth()+1)}}}this.render("right")},close:function(c,b){if(!$(this.picker)){return}var a=($chk(c)&&c.target!=this.picker&&!this.picker.hasChild(c.target)&&c.target!=this.visual);if(b||a){if(this.options.useFadeInOut){this.picker.set("tween",{duration:this.options.animationDuration/2,onComplete:this.destroy.bind(this)}).tween("opacity",1,0)}else{this.destroy()}}},destroy:function(){this.picker.destroy();this.picker=null;this.options.onClose()},select:function(a){this.choice=$merge(this.choice,a);var b=this.dateFromObject(this.choice);this.input.set("value",this.format(b,this.options.inputOutputFormat));this.visual.set("value",this.format(b,this.options.format));this.options.onSelect(b);if(this.options.inputID){$(this.options.inputID).value=this.visual.value}this.close(null,true)},leadZero:function(a){return a<10?"0"+a:a},format:function(c,g){var e="";var d=c.getHours();var a=c.getMonth();for(var b=0;b<g.length;b++){switch(g.charAt(b)){case"\\":b++;e+=g.charAt(b);break;case"y":e+=(100+c.getYear()+"").substring(1);break;case"Y":e+=c.getFullYear();break;case"m":e+=this.leadZero(a+1);break;case"n":e+=(a+1);break;case"M":e+=this.options.months[a].substring(0,this.options.monthShort);break;case"F":e+=this.options.months[a];break;case"d":e+=this.leadZero(c.getDate());break;case"j":e+=c.getDate();break;case"D":e+=this.options.days[c.getDay()].substring(0,this.options.dayShort);break;case"l":e+=this.options.days[c.getDay()];break;case"G":e+=d;break;case"H":e+=this.leadZero(d);break;case"g":e+=(d%12?d%12:12);break;case"h":e+=this.leadZero(d%12?d%12:12);break;case"a":e+=(d>11?"pm":"am");break;case"A":e+=(d>11?"PM":"AM");break;case"i":e+=this.leadZero(c.getMinutes());break;case"s":e+=this.leadZero(c.getSeconds());break;case"U":e+=Math.floor(c.valueOf()/1000);break;default:e+=g.charAt(b)}}return e},unformat:function(h,j){var k=new Date();var e={};var l,b;h=h.toString();for(var g=0;g<j.length;g++){l=j.charAt(g);switch(l){case"\\":r=null;g++;break;case"y":r="[0-9]{2}";break;case"Y":r="[0-9]{4}";break;case"m":r="0[1-9]|1[012]";break;case"n":r="[1-9]|1[012]";break;case"M":r="[A-Za-z]{"+this.options.monthShort+"}";break;case"F":r="[A-Za-z]+";break;case"d":r="0[1-9]|[12][0-9]|3[01]";break;case"j":r="[1-9]|[12][0-9]|3[01]";break;case"D":r="[A-Za-z]{"+this.options.dayShort+"}";break;case"l":r="[A-Za-z]+";break;case"G":case"H":case"g":case"h":r="[0-9]{1,2}";break;case"a":r="(am|pm)";break;case"A":r="(AM|PM)";break;case"i":case"s":r="[012345][0-9]";break;case"U":r="-?[0-9]+$";break;default:r=null}if($chk(r)){b=h.match("^"+r);if($chk(b)){e[l]=b[0];h=h.substring(e[l].length)}else{if(this.options.debug){alert("Fatal Error in DatePicker\n\nUnexpected format at: '"+h+"' expected format character '"+l+"' (pattern '"+r+"')")}return k}}else{h=h.substring(1)}}for(l in e){var f=e[l];switch(l){case"y":k.setFullYear(f<30?2000+f.toInt():1900+f.toInt());break;case"Y":k.setFullYear(f);break;case"m":case"n":k.setMonth(f-1);break;case"M":f=this.options.months.filter(function(c,a){return c.substring(0,this.options.monthShort)==f}.bind(this))[0];case"F":k.setMonth(this.options.months.indexOf(f));break;case"d":case"j":k.setDate(f);break;case"G":case"H":k.setHours(f);break;case"g":case"h":if(e.a=="pm"||e.A=="PM"){k.setHours(f==12?0:f.toInt()+12)}else{k.setHours(f)}break;case"i":k.setMinutes(f);break;case"s":k.setSeconds(f);break;case"U":k=new Date(f.toInt()*1000)}}return k}});