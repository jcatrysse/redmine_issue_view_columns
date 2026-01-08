/* eslint-env jquery */
(function ($) {
  'use strict';

  function cloneHiddenInput($checkbox) {
    var name = $checkbox.attr('name');
    var value = $checkbox.val();
    var $clone = $('<input>', {
      type: 'hidden',
      name: name,
      value: value,
      class: 'ivc-relation-clone'
    });
    $checkbox.closest('td').append($clone);
  }

  function clearClones($row) {
    $row.find('input.ivc-relation-clone').remove();
  }

  function getCheckboxValues($checkboxes) {
    return $checkboxes.filter(':checked').map(function () {
      return $(this).val();
    }).get();
  }

  function setCheckboxValues($checkboxes, values) {
    var lookup = {};
    (values || []).forEach(function (value) {
      lookup[String(value)] = true;
    });
    $checkboxes.each(function () {
      var $checkbox = $(this);
      $checkbox.prop('checked', !!lookup[$checkbox.val()]);
    });
  }

  function readPrevious($toggle) {
    var raw = $toggle.data('previous');
    if (!raw) return [];
    return String(raw).split(',').filter(function (value) {
      return value.length > 0;
    });
  }

  function writePrevious($toggle, values) {
    $toggle.data('previous', (values || []).join(','));
  }

  function setRowState($toggle, checked) {
    var targetClass = $toggle.data('target');
    if (!targetClass) return;

    var $row = $('.' + targetClass).first().closest('tr');
    var $checkboxes = $row.find('input.ivc-relation-checkbox');
    clearClones($row);

    if (checked) {
      writePrevious($toggle, getCheckboxValues($checkboxes));
      $checkboxes.each(function () {
        var $checkbox = $(this);
        $checkbox.prop('checked', true).prop('disabled', true);
        cloneHiddenInput($checkbox);
      });
    } else {
      $checkboxes.prop('disabled', false);
      setCheckboxValues($checkboxes, readPrevious($toggle));
    }
  }

  function bindHandlers() {
    $('.ivc-check-all-toggle').off('change.ivc').on('change.ivc', function () {
      setRowState($(this), $(this).is(':checked'));
    });

    $('.ivc-check-all-toggle:checked').each(function () {
      setRowState($(this), true);
    });
  }

  $(document).ready(bindHandlers);
  $(document).on('ajax:complete', bindHandlers);
})(jQuery);
