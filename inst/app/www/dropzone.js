// Drag and Drop enhancement for Shiny fileInput
$(function() {
  function initDropzones() {
    $(".dropzone").each(function() {
      var $dropzone = $(this);
      if ($dropzone.data("dropzone-init")) return;
      $dropzone.data("dropzone-init", true);

      // Find the native Shiny fileInput inside
      var $fileInput = $dropzone.find("input[type='file']");
      if (!$fileInput.length) return;

      var $fileInfo = $dropzone.find(".dropzone-file-info");
      var $fileName = $dropzone.find(".dropzone-file-name");
      var $fileSize = $dropzone.find(".dropzone-file-size");

      var suppressClick = false;

      // Click on dropzone triggers the native file input
      $dropzone.on("click", function(e) {
        if (suppressClick) return;
        $fileInput.trigger("click");
      });

      // Prevent file input click from bubbling back to dropzone
      $fileInput.on("click", function(e) {
        e.stopPropagation();
      });

      // Drag highlight
      $dropzone.on("dragover dragenter", function(e) {
        e.preventDefault();
        e.stopPropagation();
        $dropzone.addClass("dragover");
      });

      $dropzone.on("dragleave dragend", function(e) {
        e.preventDefault();
        e.stopPropagation();
        $dropzone.removeClass("dragover");
      });

      // Drop handler - set files on the native Shiny input
      $dropzone.on("drop", function(e) {
        e.preventDefault();
        e.stopPropagation();
        $dropzone.removeClass("dragover");

        var dt = e.originalEvent && e.originalEvent.dataTransfer;
        if (!dt || !dt.files || !dt.files.length) return;

        var file = dt.files[0];
        var ext = (file.name.split(".").pop() || "").toLowerCase();

        if (["esqapp", "zip"].indexOf(ext) === -1) {
          Shiny.notifications.show({
            html: "Please upload a .esqapp or .zip file",
            type: "error",
            duration: 5000
          });
          return;
        }

        // Set file on the native Shiny fileInput
        try {
          var list = new DataTransfer();
          list.items.add(file);
          $fileInput[0].files = list.files;
          // Trigger change to notify Shiny
          $fileInput.trigger("change");
          showFileInfo(file);
        } catch (err) {
          Shiny.notifications.show({
            html: "Drag-drop not supported in this browser",
            type: "error",
            duration: 5000
          });
        }

        // Prevent ghost click
        suppressClick = true;
        setTimeout(function() { suppressClick = false; }, 300);
      });

      // When file is selected via native input, show info
      $fileInput.on("change", function() {
        var files = this.files;
        if (files && files.length > 0) {
          showFileInfo(files[0]);
        } else {
          $fileInfo.removeClass("show");
        }
      });

      function showFileInfo(file) {
        var ext = (file.name.split(".").pop() || "").toLowerCase();
        if (["esqapp", "zip"].indexOf(ext) !== -1) {
          $fileName.text(file.name);
          $fileSize.text(formatFileSize(file.size));
          $fileInfo.addClass("show");
        }
      }
    });
  }

  function formatFileSize(bytes) {
    if (bytes === 0) return "0 Bytes";
    var k = 1024;
    var sizes = ["Bytes", "KB", "MB", "GB"];
    var i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i];
  }

  // Init on page load
  initDropzones();

  // Re-init when Shiny updates UI
  $(document).on("shiny:value", function() {
    setTimeout(initDropzones, 100);
  });
});
