/* eslint-env jquery */
/*!
 * Redmine Issue View Columns
 * better_subtasks_table.js (lightweight + robust)
 *
 * - Collapsed on page load when total > limit
 * - Toggle works after add/remove (delegated)
 * - Label is corrected immediately after relations block is re-rendered
 * - DOM is the source of truth (class-based)
 *
 * Turn on verbose logs in Firefox console by: window.IVC_DEBUG = true
 */
(function ($) {
    'use strict';

    // -----------------------------
    // Config & Selectors
    // -----------------------------
    var SELECTORS = {
        WRAPPER: '.ivc-relations-wrapper',
        TOGGLE:  '.ivc-relations-toggle',
        ROWS:    'table.list.issues tbody tr',
        AUTOSCROLL_TARGETS: '#issue_tree, #relations'
    };

    var CLASSES = {
        HIDDEN: 'ivc-hidden'
    };

    // Defaults if data-* labels are not present
    var DEFAULT_LABELS = {
        collapsed: 'Show all related issues',
        expanded:  'Show fewer related issues'
    };

    // Enable verbose logging by setting window.IVC_DEBUG = true in the console
    var DEBUG = !!window.IVC_DEBUG;
    function dbg() {
        if (!DEBUG) return;
        var args = Array.prototype.slice.call(arguments);
        args.unshift('[ivc]');
        console.debug.apply(console, args);
    }

    // -----------------------------
    // Utilities
    // -----------------------------
    function getLimit($wrap) {
        // Accept both data-limit and data-relation-limit to be tolerant of view markup
        var raw = $wrap.attr('data-limit') || $wrap.attr('data-relation-limit');
        if (raw == null) raw = $wrap.data('limit') || $wrap.data('relationLimit');
        var n = parseInt(raw, 10);
        return isNaN(n) ? 0 : n;
    }

    function rows($wrap) {
        // Always re-query; DOM may be replaced by AJAX
        return $wrap.find(SELECTORS.ROWS);
    }

    function toggleEl($wrap) {
        return $wrap.find(SELECTORS.TOGGLE);
    }

    function readLabel($toggle, which) {
        if (!$toggle || !$toggle.length) {
            return which === 'expanded' ? DEFAULT_LABELS.expanded : DEFAULT_LABELS.collapsed;
        }
        var attr = which === 'expanded' ? 'data-expanded-label' : 'data-collapsed-label';
        var data = which === 'expanded' ? 'expandedLabel'      : 'collapsedLabel';
        return (
            $toggle.attr(attr) ||
            $toggle.data(data) ||
            (which === 'expanded' ? DEFAULT_LABELS.expanded : DEFAULT_LABELS.collapsed)
        );
    }

    // Robust label writer: preserves icons (if any) and updates aria/title
    function writeLabel($toggle, text) {
        if (!$toggle || !$toggle.length) return;

        // Prefer a dedicated span if present
        var $span = $toggle.find('.ivc-relations-toggle-label');
        if ($span.length) {
            $span.text(text);
        } else if ($toggle.children().length === 0) {
            $toggle.text(text);
        } else {
            // Replace first text node; fallback to text()
            var updated = false;
            $toggle.contents().each(function () {
                if (this.nodeType === 3) { // text node
                    this.nodeValue = text;
                    updated = true;
                    return false;
                }
            });
            if (!updated) $toggle.text(text);
        }

        $toggle.attr('aria-label', text).attr('title', text);
    }

    // Class-based collapsed detection: no reliance on :hidden timing
    function isCollapsed($wrap) {
        var limit = getLimit($wrap);
        var $rows = rows($wrap);
        if (limit <= 0 || $rows.length <= limit) return false;
        var $extra = $rows.slice(limit);
        var totalExtra = $extra.length;
        var hiddenByClass = $extra.filter('.' + CLASSES.HIDDEN).length;
        return hiddenByClass === totalExtra && totalExtra > 0;
    }

    function setCollapsed($wrap, collapsed) {
        var limit = getLimit($wrap);
        var $rows = rows($wrap);

        if (limit <= 0 || $rows.length <= limit) {
            $rows.removeClass(CLASSES.HIDDEN);
        } else if (collapsed) {
            $rows.removeClass(CLASSES.HIDDEN).slice(limit).addClass(CLASSES.HIDDEN);
        } else {
            $rows.removeClass(CLASSES.HIDDEN);
        }
        updateToggle($wrap);
    }

    function updateToggle($wrap) {
        var $toggle = toggleEl($wrap);
        if (!$toggle.length) return;

        var limit = getLimit($wrap);
        var $rows = rows($wrap);
        var needed = limit > 0 && $rows.length > limit;

        $toggle.toggle(needed);

        var expanded = !isCollapsed($wrap);
        var label = expanded ? readLabel($toggle, 'expanded') : readLabel($toggle, 'collapsed');
        writeLabel($toggle, label);
        $toggle.attr('aria-expanded', expanded ? 'true' : 'false');

        dbg('updateToggle', {
            limit: limit,
            total: $rows.length,
            needed: needed,
            expanded: expanded,
            label: label
        });
    }

    function initWrapperCollapsedOnLoad($wrap) {
        // Force collapsed on page load if limit exceeded
        var limit = getLimit($wrap);
        var $rows = rows($wrap);
        var shouldCollapse = limit > 0 && $rows.length > limit;

        dbg('initWrapperCollapsedOnLoad', { limit: limit, total: $rows.length, shouldCollapse: shouldCollapse });

        if (shouldCollapse) {
            $rows.removeClass(CLASSES.HIDDEN).slice(limit).addClass(CLASSES.HIDDEN);
        } else {
            $rows.removeClass(CLASSES.HIDDEN);
        }
        updateToggle($wrap);
    }

    function initAllCollapsedOnLoad() {
        $(SELECTORS.AUTOSCROLL_TARGETS).addClass('autoscroll'); // idempotent
        $(SELECTORS.WRAPPER).each(function () { initWrapperCollapsedOnLoad($(this)); });
    }

    // -----------------------------
    // Toggle (delegated)
    // -----------------------------
    $(document).on('click', SELECTORS.TOGGLE, function (e) {
        e.preventDefault();
        var $wrap = $(this).closest(SELECTORS.WRAPPER);
        if (!$wrap.length) return;

        var willCollapse = !isCollapsed($wrap) /* expanded now -> collapse */;
        dbg('toggle click', { willCollapse: willCollapse });
        setCollapsed($wrap, willCollapse);
    });

    // -----------------------------
    // Page load: collapse-by-default
    // -----------------------------
    $(function () {
        initAllCollapsedOnLoad();
        startRelationsObserver(); // updates label immediately after add/remove
    });

    // -----------------------------
    // Observe #relations for DOM replacement
    // This ensures the label is corrected *immediately* after add/remove,
    // without relying on ajaxComplete timing.
    // -----------------------------
    function startRelationsObserver() {
        var rel = document.getElementById('relations');
        if (!rel || typeof MutationObserver === 'undefined') {
            // Fallback: at least refresh labels after any ajax complete
            $(document).ajaxComplete(function () {
                $('#relations').find(SELECTORS.WRAPPER).each(function () { updateToggle($(this)); });
            });
            return;
        }

        var obs = new MutationObserver(function (mutations) {
            var relevant = false;
            for (var i = 0; i < mutations.length; i++) {
                var m = mutations[i];
                if ((m.addedNodes && m.addedNodes.length) || (m.removedNodes && m.removedNodes.length)) {
                    relevant = true; break;
                }
            }
            if (!relevant) return;

            // Next frame: new DOM is in
            (window.requestAnimationFrame || setTimeout)(function () {
                $('#relations').find(SELECTORS.WRAPPER).each(function () {
                    var $wrap = $(this);
                    // Do NOT auto-collapse here — keep what server rendered (usually expanded after add)
                    // Just ensure toggle visibility + label are correct right away.
                    updateToggle($wrap);

                    dbg('observer updated', {
                        limit: getLimit($wrap),
                        total: rows($wrap).length,
                        collapsed: isCollapsed($wrap),
                        label: toggleEl($wrap).text()
                    });
                });
            }, 0);
        });

        obs.observe(rel, { childList: true, subtree: true });
        dbg('relations observer started');
    }

})(jQuery);
