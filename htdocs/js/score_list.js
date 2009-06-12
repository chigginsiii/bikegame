$(document).ready(function(){
  // hide the forms
  $("div.ride_edit").hide();
  $("div.ride_details").hide();

  $("div.ride").each(function () {

    var ride = this; 
    $(ride).find("a.ride_edit_click").click(function(){
      var ride_ed = $(ride).find("div.ride_edit:first");
      if ( $(ride_ed).is(":hidden") ) {
        $(ride).addClass("ride_expanded");
        $(ride_ed).slideDown("slow");
      } else {
        $(ride_ed).slideUp("slow");
        $(ride).removeClass("ride_expanded");
      }   
    });      

    $(ride).find("a.ride_details_click").click(function(){
      var ride_d = $(ride).find("div.ride_details:first");
      if ( $(ride_d).is(":hidden") ) {
        $(ride_d).slideDown("slow");
      } else {
        $(ride_d).slideUp("slow");
      }   
    });      

  });

});
