window.onbeforeunload = function(event) {
  // This message is displayed as a confirmation dialog
  event.preventDefault();
  event.returnValue = '';
  return '';
};
