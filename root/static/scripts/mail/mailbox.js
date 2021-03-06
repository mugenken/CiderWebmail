var droppables;
var current_message;
var loading_message;

function get_target_node(event) {
    var target = event.target || event.srcElement;
    while (target && target.nodeType == 3) target = target.parentNode;
    return target;
}

function show_message(target) {
    var uid = target.id.replace('link_', '');
    var messages_pane = $('messages_pane');

    $('message_view').innerHTML = loading_message;
    $('loading_message').style.display = 'block';
    $('help_message').style.display = 'none';

    if (! $('content').hasClass('message_display')) {
        var message_divider_top = Cookie.read('message_divider_message_display_top');
        $('content').addClass('message_display');
        messages_pane.style.bottom = message_divider_top ? $('messages_pane').parentNode.offsetHeight - message_divider_top + 'px' : '70%';
        $('message_view').style.top     = message_divider_top ? message_divider_top + 'px' : '30%';
        $('message_divider').style.top  = message_divider_top ? message_divider_top + 'px' : '30%';
    }

    if (current_message)
        current_message.removeClass('active');

    current_message = $(target.parentNode.parentNode);
    current_message.addClass('seen');
    current_message.addClass('active');

    if (current_message.offsetTop + current_message.offsetHeight > messages_pane.scrollTop + messages_pane.offsetHeight)
        messages_pane.scrollTop = current_message.offsetTop + current_message.offsetHeight - messages_pane.offsetHeight;

    if (current_message.offsetTop < messages_pane.scrollTop)
        messages_pane.scrollTop = current_message.offsetTop;

    var myHTMLRequest = new Request.HTML({
        onSuccess: function(responseTree, responseElements, responseHTML, responseJavaScript) {
            var parsed = responseHTML.match(/([\s\S]*?)<div>([\s\S]*)<\/div>/);
            $('message_view').innerHTML = parsed[2];
            update_foldertree(parsed[1], responseTree);
        }
    }).get(target.href + "?layout=ajax");
}

function show_previous_message() {
    var previous = current_message.previousSibling;

    if (previous && previous.nodeType != 1) previous = previous.previousSibling;

    if (! previous || ! previous.id) { // first row is the group header
        var prev_group = current_message.parentNode.previousSibling;
        if (prev_group) {
            var prev_messages = prev_group.getElementsByTagName('tr');
            previous = prev_messages[prev_messages.length - 1];
        }
    }

    if (previous && previous.id) { // first row of the table is table header
        show_message(document.getElementById(previous.id.replace('message', 'link'))); //left
        return 1;
    }

    return 0;
}

function show_next_message() {
    var next = current_message.nextSibling;

    if (next && next.nodeType != 1) next = next.nextSibling;

    if (! next) {
        var next_group = current_message.parentNode.nextSibling;
        if (next_group && next_group.nodeType != 1) next_group = next_group.nextSibling;
        if (next_group)
            next = next_group.getElementsByTagName('tr')[1]; // first row is the group header
    }

    if (next) {
        show_message(document.getElementById(next.id.replace('message', 'link'))); //left
        return 1;
    }

    return 0;
}

function delete_message(icon) {
    new Request({url: icon.parentNode.href, onSuccess: update_foldertree, headers: {'X-Request': 'AJAX'}}).send();

    var group = icon.parentNode.parentNode.parentNode.parentNode;
    group.removeChild(icon.parentNode.parentNode.parentNode);
    if (group.getElementsByTagName('tr').length == 1)
        group.parentNode.removeChild(group);
}

window.addEvent('load', function() {
    var selected = [];
    droppables = $('folder_tree').getElements('.folder');
    loading_message = $('message_view').innerHTML;
    var cancelled = false;

    function start(event) {
        var target = get_target_node(event);
        var tag_name = target.tagName.toLowerCase();

        if (tag_name == 'img' && target.id && target.id.indexOf('icon_') == 0) {
            if (! selected.length) selected.push(target.parentNode.parentNode);
            add_drag_and_drop(target, event, droppables, selected);
            stop_propagation(event);
        }
        else if (tag_name == 'td' && target.parentNode.id && target.parentNode.id.indexOf('message_') == 0) {
            if (! selected.length) selected.push(target.parentNode);
            var icon = target.parentNode.getElementsByTagName('img')[0];
            add_drag_and_drop(icon, event, droppables, selected);
            stop_propagation(event);
        }
        else if (tag_name == 'a' && target.id && target.id.indexOf('link_') == 0) {
            if (! selected.length) selected.push(target.parentNode.parentNode);
            var icon = target.parentNode.parentNode.getElementsByTagName('img')[0];
            cancelled = false;
            setTimeout(function () { if (!cancelled) add_drag_and_drop(icon, event, droppables, selected); }, 200);
            stop_propagation(event);
        }
    }

    function handle_click(event) {
        var target = get_target_node(event);
        var tagname = target.tagName.toLowerCase();

        if (tagname == 'a' && target.id && target.id.indexOf('link_') == 0) {
            cancelled = true;
            show_message(target);
            stop_propagation(event);
        }
        else if (tagname == 'img' && target.id && target.id.indexOf('delete_') == 0) {
            delete_message(target);
            stop_propagation(event);
        }
        else {
            while (tagname != 'body' && tagname != 'tr') {
                if (tagname == 'a') break; // let links continue to work

                target = target.parentNode;
                if (target.nodeType != 1) break; // no use continuing here
                tagname = target.tagName.toLowerCase();
            }

            if (tagname == 'tr' && target.id && target.id.indexOf('message_') == 0) {
                if (target.hasClass('selected')) {
                    target.removeClass('selected');
                    selected.erase(target);
                }
                else {
                    target.addClass('selected');
                    selected.push(target);
                }
            }
        }
    }

    add_event_listener('mousedown', start, false);
    add_event_listener('click', handle_click, false);
    add_event_listener('keyup', function (event) {
            switch (event.keyCode) {
                case 37: // left
                    show_previous_message();
                    break;
                case 75: // k
                    show_previous_message();
                    break;
                case 39: // right
                    show_next_message();
                    break;
                case 74: // j
                    show_next_message();
                    break;
                case 32: // space bar
                    document.getElementById('message_view').scrollTop = (document.getElementById('message_view').scrollTop + 250);
                    break;
                case 38: // arrow up
                    document.getElementById('message_view').scrollTop = (document.getElementById('message_view').scrollTop - 25);
                    break;
                case 40: // arrow down
                    document.getElementById('message_view').scrollTop = (document.getElementById('message_view').scrollTop + 25);
                    break;
            }
        }, false);

    fetch_new_rows(100, 100);
});

function fetch_new_rows(start_index, length) {
    var start = 'start=' + start_index
    var href = location.search.match(/start=/) ? location.href.replace(/start=\d+/, start) : (location.href.match(/\?/) ? location.href + '&' + start : location.href + '?' + start);

    new Request({url: href + ';layout=ajax', onSuccess: function(responseText, responseXML) {
        // this hack is presented to you by Microsoft
        var dummy = document.createElement('span');
        dummy.innerHTML = '<table>' + responseText.match(/<table[^>]+id="message_list"[^>]*>([\S\s]*)<\/table>/)[1] + '</table>'; // responseXML.getElementById doesn't work in IE
        var new_rows = dummy.firstChild;

        while (new_rows.firstChild.nodeType == 3)
            new_rows.removeChild(new_rows.firstChild);
        new_rows.removeChild(new_rows.firstChild);

        dummy.innerHTML = new_rows.parentNode.innerHTML;
        new_rows = dummy.firstChild.nodeType == 1 ? dummy.firstChild : dummy.firstChild.nextSibling;

        var child = new_rows.firstChild;
        while (child) { // remove text and comment nodes as we are only really interested in tbodys
            var next = child.nextSibling;
            if (child.nodeType != 1) {
                new_rows.removeChild(child);
            }
            child = next;
        }

        if (new_rows.childNodes.length && new_rows.firstChild.childNodes.length) { // IE has an empty tbody if now rows were added
            var message_list = document.getElementById('message_list');
            for (var i = 0; i < new_rows.childNodes.length ; i++)
                message_list.appendChild(new_rows.childNodes[i].cloneNode(true));

            var messages_pane = $('messages_pane');
            var fetcher = function (event) {
                if (messages_pane.scrollTop > messages_pane.scrollHeight - messages_pane.offsetHeight * 3) {
                    messages_pane.removeEvent('scroll', fetcher);
                    var length = 100;
                    fetch_new_rows(start_index + length, length);
                }
            };
            messages_pane.addEvents({scroll: fetcher});
        }
        else {
            $('fetching_message').style.display = 'none';
        }
    }}).send();
}

function update_foldertree(responseText, responseXML) {
    var folder_tree = responseText.match(/<ul[^>]*id="folder_tree"[^>]*>([\s\S]*)<\/ul>/i)[1]; // responseXML.getElementById doesn't work in IE
    document.title = document.title.replace(/- \(\d+\)$/, '- (' + responseText.match(/<div id="unseen">(\d+)<\/div>/)[1] + ')');
    document.getElementById('folder_tree').innerHTML = folder_tree;
    droppables = $('folder_tree').getElements('.folder');
}

function add_drag_and_drop(message, event, droppables, selected) {
    var overed_prev;
    var droppables_positions = {};
    droppables.each(function (droppable) {
        droppables_positions[droppable.title] = droppable.getCoordinates();
    });

    function drag(event) {
        var overed = droppables.filter(function (el) {
                el = droppables_positions[el.title];
                return (event.client.x > el.left && event.client.x < el.right && event.client.y < el.bottom && event.client.y > el.top);
            }).getLast();

        if (overed_prev != overed) {
            if (overed_prev) {
                overed_prev.removeClass('hover');
            }
            overed_prev = overed;
            if (overed){
                overed.addClass('hover');
            }
        }
        dragger.style.left = event.client.x + 'px';
        dragger.style.top  = event.client.y + 'px';
    }

    function drop(event) {
        document.removeEvent('mousemove', drag);
        document.removeEvent('mouseup', drop);

        dragger.parentNode.removeChild(dragger);

        if (overed_prev) {
            selected.each(function (message) {
                var uid = message.id.replace('message_', '');
                var href = location.href.replace(/\/?(\?.*)?$/, '');
                new Request({url: href + "/" + uid + "/move?target_folder=" + overed_prev.title, onSuccess: update_foldertree, headers: {'X-Request': 'AJAX'}}).send();

                var tbody = message.parentNode
                tbody.removeChild(message);

                var children = 0;
                for (var i = 0; i < tbody.childNodes.length; i++)
                    if (tbody.childNodes[i].nodeType == 1) children++;
                if (children == 1)
                    tbody.parentNode.removeChild(tbody);
            });
        }

        selected.each(function(message) {
            message.removeClass('selected');
        });
        selected.splice(0, selected.length);
    }

    var dragger = document.createElement('ul');
    selected.each(function (message) {
        var li = document.createElement('li');
        li.innerHTML = $(message).getElements('td.subject a')[0].innerHTML;
        dragger.appendChild(li);
    });

    dragger.className = 'dragger';
    dragger.style.left = event.clientX + 'px';
    dragger.style.top  = event.clientY + 'px';

    document.body.appendChild(dragger);

    document.addEvents({mousemove: drag, mouseup: drop});
}
