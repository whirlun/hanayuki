function pushbtnclick(id) {

    var PostVal = {
        "title": title,
        "content": content,
        "cat": cat,
        "accesslevel": accesslevel
    }
    $.ajax({
        type: 'POST',
        contentType: 'application/json',
        url: '/add',
        data: JSON.stringify(PostVal),
        success: () => {var success = "<div class='text-center'><span class='glyphicon glyphicon-ok' aria-hidden='true' font-size='50px'></span></div><p class='lead text-center'>成功发送讨论串</p><br /><div class='text-center'><small>点击任意处以关闭此窗口</small>"
        document.getElementById('ModalContent').innerHTML = success},
        error: () => {var error = "<div class='text-center'><span class='glyphicon glyphicon-remove' aria-hidden='true' font-size='50px'></span></div><p class='lead text-center'>错误-发生内部错误，请稍后再试</p>"
    document.getElementById('ModalContent').innerHTML = error}
    })
}
