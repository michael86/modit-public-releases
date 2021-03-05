window.addEventListener('message', function(event) {
    let item = event.data;

    if (item.response == 'openTarget') {
        $(".target-label").html("");

        $('.target-wrapper').show();

        $(".target-eye").css("color", "black");
    } else if (item.response == 'closeTarget') {
        $(".target-label").html("");

        $('.target-wrapper').hide();
    } else if (item.response == 'validTarget') {
        $(".target-label").html("");

        $.each(item.data, function(index, item) {
            $(".target-label").append(`
            <div id="target-${index}">
                <span class="target-icon">
                    <i class="${item.icon}"></i>
                </span>&nbsp${item.label}
            </div>`);
            $("#target-" + index).hover((e) => {
                $("#target-" + index).css("color", e.type === "mouseenter" ? "rgb(30,144,255)" : "white")
            })

            $(`#target-${index}`).addClass('option');

            $("#target-" + index).data('TargetData', item.event);
            $("#target-" + index).data('TargetArgs', item.args);
        });

        $(".target-eye").css("color", "rgb(30,144,255)");
    } else if (item.response == 'leftTarget') {
        $(".target-label").html("");

        $(".target-eye").css("color", "black");
    }
});

$(document).on('mousedown', (event) => {
    let element = event.target;

    if (element.id.split("-")[0] === 'target') {
        let TargetData = $("#" + element.id).data('TargetData');
        let TargetArgs = $("#" + element.id).data('TargetArgs');

        $.post('http://bt-target/selectTarget', JSON.stringify({
            event: TargetData,
            args: TargetArgs
        }));

        $(".target-label").html("");
        $('.target-wrapper').hide();
    }
});

$(document).on('keydown', function() {
    switch (event.keyCode) {
        case 27: // ESC
            $(".target-label").html("");
            $('.target-wrapper').hide();
            $.post('http://bt-target/closeTarget');
            break;
    }
});