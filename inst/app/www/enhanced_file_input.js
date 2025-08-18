// Enhanced File Input with Drag and Drop
$(function() {
  function initDropzones() {
    $("[id$='-dropzone']").each(function() {
      var dropzone = $(this);
      if (dropzone.data("dropzone-init")) return; // already initialized
      dropzone.data("dropzone-init", true);

      var fileInput = dropzone.find("input[type='file']").first();
      if (!fileInput.length) return;

      // Prevent double opening after drop
      var suppressNextClick = false;

      // Highlight on drag
      dropzone.on("dragover dragenter", function(e) {
        e.preventDefault(); e.stopPropagation();
        dropzone.addClass("dragover");
      });

      dropzone.on("dragleave dragend", function(e) {
        e.preventDefault(); e.stopPropagation();
        dropzone.removeClass("dragover");
      });

      // Drop handler
      dropzone.on("drop", function(e) {
        e.preventDefault(); e.stopPropagation();
        dropzone.removeClass("dragover");

        var dt = e.originalEvent && e.originalEvent.dataTransfer;
        if (!dt || !dt.files || !dt.files.length) return;

        var file = dt.files[0];
        var ext = (file.name.split(".").pop() || "").toLowerCase();
        if (["xlsx","xls"].indexOf(ext) === -1) {
          showFeedback(dropzone, "Invalid file type. Please select .xlsx or .xls", "error");
          return;
        }

        try {
          var list = new DataTransfer();
          list.items.add(file);
          fileInput[0].files = list.files;
          fileInput.trigger("change");
          showFeedback(dropzone, "File selected: " + file.name + " • " + (file.size/1024).toFixed(1) + " KB", "success");
        } catch (err) {
          // Fallback
          showFeedback(dropzone, "Drag-drop not supported; click to choose file.", "error");
          // Only click the input if we really need to
          fileInput.trigger("click");
        }

        // Prevent the "ghost click" that some browsers emit after drop
        suppressNextClick = true;
        setTimeout(function(){ suppressNextClick = false; }, 250);
      });

      // Only clicks on the dropzone *itself* (empty area) open the picker
      dropzone.on("click", function(e) {
        // If click originated from a child (button/label/input), do nothing
        if (e.target !== e.currentTarget) return;
        if (suppressNextClick) return;
        fileInput.trigger("click");
      });

      // If user clicks the native input/button/label, stop bubbling to zone
      fileInput.on("click", function(e) {
        e.stopPropagation();
      });

      function showFeedback(zone, msg, type) {
        zone.find(".upload-feedback").remove();
        var el = $('<div class="upload-feedback" style="margin-top:10px;"></div>');
        el.css("color", type === "success" ? "#28a745" : "#dc3545").text(msg);
        zone.append(el);
        if (type === "error") {
          setTimeout(function(){ el.fadeOut(300, function(){ el.remove(); }); }, 3000);
        }
      }
    });
  }

  // run once on page load
  initDropzones();

  // re-run when Shiny inserts/replaces UI
  $(document).on("shiny:value", function(){ initDropzones(); });
});
