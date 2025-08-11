// Enhanced File Input with Drag and Drop
$(document).ready(function() {
  
  // Add drag and drop functionality to file input areas
  function initializeFileUploadEnhancements() {
    const fileInputCards = $('.card');
    
    fileInputCards.each(function() {
      const card = $(this);
      const fileInput = card.find('input[type="file"]');
      
      if (fileInput.length > 0) {
        // Add drag and drop event listeners
        card.on('dragover', function(e) {
          e.preventDefault();
          e.stopPropagation();
          card.addClass('dragover');
          card.css('border-color', '#28a745');
          card.css('background-color', '#e8f5e8');
        });
        
        card.on('dragleave', function(e) {
          e.preventDefault();
          e.stopPropagation();
          card.removeClass('dragover');
          card.css('border-color', '#007bff');
          card.css('background-color', '');
        });
        
        card.on('drop', function(e) {
          e.preventDefault();
          e.stopPropagation();
          card.removeClass('dragover');
          card.css('border-color', '#007bff');
          card.css('background-color', '');
          
          const files = e.originalEvent.dataTransfer.files;
          if (files.length > 0) {
            const file = files[0];
            
            // Check file type
            const validExtensions = ['xlsx', 'xls'];
            const fileExtension = file.name.split('.').pop().toLowerCase();
            
            if (validExtensions.includes(fileExtension)) {
              // Simulate file selection
              const dt = new DataTransfer();
              dt.items.add(file);
              fileInput[0].files = dt.files;
              
              // Trigger change event
              fileInput.trigger('change');
              
              // Show success feedback
              showFileUploadFeedback(card, file, 'success');
            } else {
              showFileUploadFeedback(card, file, 'error');
            }
          }
        });
        
        // Click to select file
        card.on('click', function(e) {
          if (!$(e.target).is('input, button')) {
            fileInput.click();
          }
        });
      }
    });
  }
  
  // Show file upload feedback
  function showFileUploadFeedback(card, file, type) {
    const feedbackDiv = $('<div class="upload-feedback"></div>');
    
    if (type === 'success') {
      feedbackDiv.html(`
        <div style="color: #28a745; margin-top: 10px;">
          <i class="fas fa-check-circle"></i> File selected: ${file.name}
          <small style="display: block; color: #6c757d;">
            Size: ${(file.size / 1024).toFixed(1)} KB
          </small>
        </div>
      `);
    } else {
      feedbackDiv.html(`
        <div style="color: #dc3545; margin-top: 10px;">
          <i class="fas fa-exclamation-circle"></i> Invalid file type
          <small style="display: block; color: #6c757d;">
            Please select an Excel file (.xlsx, .xls)
          </small>
        </div>
      `);
    }
    
    // Remove existing feedback
    card.find('.upload-feedback').remove();
    card.append(feedbackDiv);
    
    if (type === 'error') {
      setTimeout(() => {
        feedbackDiv.fadeOut(300, () => feedbackDiv.remove());
      }, 3000);
    }
  }
  
  // Initialize on page load
  initializeFileUploadEnhancements();
  
  // Re-initialize when content changes (for dynamic content)
  $(document).on('DOMSubtreeModified', function() {
    setTimeout(initializeFileUploadEnhancements, 100);
  });
  
  // Modern alternative using MutationObserver
  if (typeof MutationObserver !== 'undefined') {
    const observer = new MutationObserver(function(mutations) {
      mutations.forEach(function(mutation) {
        if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
          setTimeout(initializeFileUploadEnhancements, 100);
        }
      });
    });
    
    observer.observe(document.body, {
      childList: true,
      subtree: true
    });
  }
});