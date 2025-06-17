function applyAutoScroll() {
    $("#issue_tree, #relations").addClass("autoscroll");
}

$(document).ready(applyAutoScroll);
$(document).ajaxComplete(applyAutoScroll);
