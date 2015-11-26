$(document).ready(function() {
  $("#character_template_id").chosen({
    width: '100%',
    disable_search_threshold: 20,
  });

  $("#character_gallery_id").chosen({
    width: '100%',
    disable_search_threshold: 20,
  });
  $(".character-view-select").click(function() {
    $(".character-view-select").css('border','0px').css('padding-top','5px').css('padding-bottom','5px');
    $(this).css('border','2px black solid').css('padding-top','3px').css('padding-bottom','3px');
  });

  bindIcons();

  $("#character_gallery_id").change(function() {
    $("#character_default_icon_id").val('');
    var gallery_id = $(this).val();
    if (gallery_id == '') {
      $("#selected-gallery").hide();
      return;
    }
    
    $.get('/galleries/'+gallery_id, function (resp) {
      $("#selected-gallery .gallery").html('');
      $("#selected-gallery").show();
      for(var i = 0; i < resp.length; i++) {
        var url = resp[i]['icon']['url'];
        var keyword = resp[i]['icon']['keyword'];
        var id = resp[i]['icon']['id'];
        $("#selected-gallery .gallery").append('<img src="'+url+'" alt="'+keyword+'" title="'+keyword+'" class="icon character-icon" id="'+id+'" />');  
      }
      bindIcons();
    });
  });
});

function bindIcons() {
  $(".character-icon").click(function() {
    if($(this).hasClass('default-icon')) { return; }
    $(".default-icon").removeClass('default-icon');
    $(this).addClass('default-icon');
    var id = $(this).attr('id');

    if (gon.character_id) {
      $.post('/characters/'+gon.character_id+'/icon', {'icon_id':id}, function(resp) {});
    } else {
      $("#character_default_icon_id").val(id);
    }
  });
};