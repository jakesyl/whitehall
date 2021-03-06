(function() {
  "use strict";
  window.GOVUK = window.GOVUK || {};

  var StatisticsAnnouncementDateForm = {
    init: function(model_name) {
      this.model_name = model_name;
      this.$precisionInputs = $('input[name="' + model_name +'[precision]"]');
      this.$confirmedCheckbox = $('input[name="' + model_name +'[confirmed]"]');

      this.$confirmedCheckbox.on('click', this.togglePrecision);
    },

    togglePrecision: function() {
      if ($(this).is(':checked')) {
        StatisticsAnnouncementDateForm.fixToExactPrecision();
      };
    },

    fixToExactPrecision: function() {
      $('input[name="' + StatisticsAnnouncementDateForm.model_name +'[precision]"][value="0"]').prop('checked', true);
    }
  };

  GOVUK.StatisticsAnnouncementDateForm = StatisticsAnnouncementDateForm;
}());
