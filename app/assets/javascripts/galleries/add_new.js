$(document).ready( function() {
  fixButtons();
  $(".icon-row td:has(input)").each(function(){
    $(this).keydown(iconbit_keydown);
  });
  bindFileInput($("#icon_files"));
});


function iconbit_keydown(event) {
  //key_up = 38;
  //key_down = 40;
  if (event.which == 40 || event.which == 38 || event.which == 37 || event.which == 39) {
    this_in = $("input", this);
    switch (this_in.get(0).type) {
      case "text":
        this_in_caret = this_in.get(0).selectionStart;
        this_in_len = this_in.val().length;
        break;
      case "file":
        this_in_caret = -1;
        this_in_len = 0;
        break;
      default:
        this_in_caret = -1;
        this_in_len = 10;
        break;
    }
    consume = false;
    switch (event.which) {
      case 39:
        if (this_in_len == 0 || (this_in_caret && this_in_caret >= this_in_len)) {
          $(this).closest('td').next().find('input').focus();
          consume = true;
        } break;
      case 37:
        if (this_in_len == 0 || this_in_caret == 0) {
          $(this).closest('td').prev().find('input').focus();
          consume = true;
        }
        break;
      case 40:
        $(this).closest('tr').next().children().eq($(this).closest('td').index()).find('input').focus();
        consume = true;
        break;
      case 38:
        $(this).closest('tr').prev().children().eq($(this).closest('td').index()).find('input').focus();
        consume = true;
        break;
    }
    if (consume) event.preventDefault();
  }
}

function fixButtons() {
  $(".icon-row-add").hide().unbind();
  $(".icon-row-add").last().show();
  $(".icon-row-rem").show();
  $(".icon-row-rem").first().hide();
  bindAdd();
  bindRem();
  $("#icon-table tr.icon-row:odd td").removeClass('even').addClass("odd");
  $("#icon-table tr.icon-row:even td").removeClass('odd').addClass("even");
};

function bindAdd() {
  $(".icon-row-add").click(function () {
    addNewRow();
    fixButtons();
  });
};

function addNewRow() {
  var new_row = $(".icon-row:last").clone();
  var index = new_row.data('index') + 1;
  new_row.attr('data-index', index);

  // clear all input values in the clone
  var inputs = new_row.find('input');
  inputs.val('');

  // handle the URL field specially
  // because uploads have special UI
  var urlField = inputs.first();
  new_row.find('.conf').remove();
  urlField.show();
  urlField.attr('id', 'icons_'+index+'_url');

  new_row.insertBefore($(".submit-row"));
  $("td:has(input)", new_row).each(function(){
    $(this).keydown(iconbit_keydown);
  });
  return index;
};

function bindRem() {
  $(".icon-row-rem").click(function () {
    var rem_row = $(this).parent().parent();
    rem_row.remove();
    fixButtons();
  });
};

function bindFileInput(fileInput) {
    var form         = $('form.icon-upload');
    var submitButton = form.find('input[type="submit"]');
    var formData     = form.data('form-data');

    fileInput.fileupload({
      fileInput:       fileInput,
      url:             form.data('url'),
      type:            'POST',
      autoUpload:       true,
      formData:         formData,
      paramName:        'file', // S3 does not like nested name fields i.e. name="user[avatar_url]"
      dataType:         'XML',  // S3 returns XML if success_action_status is set to 201
      replaceFileInput: false,

      add: function (e, data) {
        var fileType = data.files[0].type;
        if (!fileType.startsWith('image/')) {
          alert("You must upload files with an image filetype such as .png or .jpg - please retry with a valid file.");
          return;
        } else if (fileType === 'image/tiff') {
          alert("Unfortunately, .tiff files are only supported by Safari - please retry with a valid file.");
          return;
        }

        formData["Content-Type"] = fileType;
        data.formData = formData;
        data.submit();
        fileInput.val('');
      },
      start: function (e) {
        submitButton.prop('disabled', true);
      },
      done: function(e, data) {
        submitButton.prop('disabled', false);

        // extract key and generate URL from response
        var key   = $(data.jqXHR.responseXML).find("Key").text();
        var url   = 'https://d1anwqy6ci9o1i.cloudfront.net/' + key;

        // create hidden field
        var iconIndex = addNewRow();
        var urlInput = $("#icons_"+iconIndex+"_url");
        var urlCell = $(urlInput.parents('td:first'));
        urlInput.hide().val(url);
        urlCell.find('.conf').remove();

        // update keyword box with data.files[0].name minus file extension
        var keyword = data.files[0].name;
        var fileExt = keyword.split('.').slice(-1)[0];
        if (fileExt != keyword)
          keyword = keyword.replace('.'+fileExt, '');
        $(".icon-row[data-index='" + iconIndex + "'] input[id$='_keyword']").val(keyword);

        var uploaded = ' Uploaded ' + data.files[0].name;
        urlCell.append("<span class='conf'><img src='/images/accept.png' alt='' title='Successfully uploaded' class='vmid' />"+uploaded+"</span>");
        cleanUpRows();
      },
      fail: function(e, data) {
        var iconIndex = data.iconIndex;
        submitButton.prop('disabled', false);
        var response = data.response().jqXHR
        var policyExpired = response.responseText.includes("Invalid according to Policy: Policy expired.");
        if (!policyExpired) { policyExpired = response.responseText.includes("Idle connections will be closed."); }
        var badFiletype = response.responseText.includes("Policy Condition failed") && response.responseText.includes('"$Content-Type", "image/"');
        var bugsData = {
          'response_status': response.status,
          'response_body': response.responseText,
          'response_text': response.statusText,
          'file_name': data.files[0].name,
          'file_type': data.files[0].type,
        };
        if (policyExpired) {
          alert("Your upload permissions appear to have expired. Please refresh the page and try again.");
        } else if (badFiletype) {
          alert("You must upload files with an image filetype such as .png or .jpg - please retry with a valid file.");
        } else {
          $.post('/bugs', bugsData);
          alert("Upload of " + data.files[0].name + " failed, Marri has been notified.");
        }
      },
    });
};

function cleanUpRows() {
  $(".icon-row").each(function (index) {
    var anySet = false;
    if ($(this).find('.conf').length > 0) { return true; }
    $(this).find('input').each(function() {
      if($(this).val() != '') {
        anySet = true;
        return false;
      }
    });
    if (!anySet) { $(this).remove(); }
  });
  $(".icon-row").each(function (index) {
    $(this).attr('data-index', index);
    $(this).find('input').first().attr('id', 'icons_'+index+'_url');
  });
  fixButtons();
};
