function setmenu() {
    var content = document.getElementById("content");
    var header = document.getElementById("header");
    var banner = document.getElementById("banner");
    var mnleft = document.getElementById("mnleft");
    var w = content.style.width;
    if (w == "") {
        content.style.width = "calc(100% - 42px)";
        header.style.width = "42px";
        banner.style.paddingLeft = "42px";
        banner.style.width = "calc(100% - 42px)";
        $(mnleft).addClass("mnhide")
    }
    else {
        content.style.width = "";
        header.style.width = "";
        banner.style.paddingLeft = "";
        banner.style.width = "";
        $(mnleft).removeClass("mnhide")
    }
}
function mnClose(o) {
    var box = o.parentNode.parentNode;
    var sub = box.getElementsByClassName("mn_sub");
    sub[0].style.display = "none";
    o.src = "./images/arrow_right.png";
    $(o).attr("onclick", "mnOpen(this)");
}
function mnOpen(o) {
    var box = o.parentNode.parentNode;
    var sub = box.getElementsByClassName("mn_sub");
    sub[0].style.display = "";
    o.src = "./images/arrow_down.png";
    $(o).attr("onclick", "mnClose(this)");
}
function beginProgress() {
    $('#progress').css({ width: 90 + '%' });
}
function endProgress() {
    //$('#progress').addClass("hide");
    $('#progress').css({ width: 100 + '%', opacity: '0', transition: 'opacity .2s' });
    setTimeout(clearProgress, 200);
    setTimeout(resetProgress, 300);
}
function clearProgress() {
    $('#progress').css({ width: 0 + '%', transition: 'width 0s' });
}
function resetProgress() {
    $('#progress').css({ opacity: '1', transition: 'width 5s' });
}
function openFullscreen(id) {
    var elem = document.getElementById(id);
    if (elem.requestFullscreen) {
        elem.requestFullscreen();
    } else if (elem.webkitRequestFullscreen) { /* Safari */
        elem.webkitRequestFullscreen();
    } else if (elem.msRequestFullscreen) { /* IE11 */
        elem.msRequestFullscreen();
    }
}
function resetTable(iFrom) {
    //Remove old data
    BtnHide("btnSua");
    BtnHide("btnCon");
    BtnHide("btnXoa");
    BtnHide("btnLuu");
    BtnHide("btnDuyet");
    BtnHide("btnDuyet2");
    BtnHide("btnDuyet3");
    BtnHide("btnHuyDuyet");
    BtnHide("btnHuyDuyet2");
    BtnHide("btnHuyDuyet3");
    BtnHide("btnTraVe");
    BtnHide("btnKhongDuyet");
    BtnHide("btnDanhGia");
    BtnHide("btnKhoa");
    BtnHide("btnMoKhoa");
    var rows = $("#gridbody tr");
    if (iFrom == null) iFrom = 1;
    for (var i = iFrom; i < rows.length; i++) //The json object has length
    {
        $(rows[i]).remove();
    }
}
function deleteRow(ele) {
    $(ele).parent().parent().remove();
}
function BtnFire() {
    var chks = $('#gridbody td.colchk input[type="checkbox"]:checked');
    var max = chks.length;
    if (max > 0) {
        BtnActive("btnXoa");
        BtnActive("btnLuu");
        BtnActive("btnDuyet");
        BtnActive("btnDuyet2");
        BtnActive("btnDuyet3");
        BtnActive("btnHuyDuyet");
        BtnActive("btnHuyDuyet2");
        BtnActive("btnHuyDuyet3");
        BtnActive("btnTraVe");
        BtnActive("btnKhongDuyet");
        BtnActive("btnDanhGia");
        BtnActive("btnKhoa");
        BtnActive("btnMoKhoa");
    }
    else {
        BtnHide("btnXoa");
        BtnHide("btnLuu");
        BtnHide("btnDuyet");
        BtnHide("btnDuyet2");
        BtnHide("btnDuyet3");
        BtnHide("btnHuyDuyet");
        BtnHide("btnHuyDuyet2");
        BtnHide("btnHuyDuyet3");
        BtnHide("btnTraVe");
        BtnHide("btnKhongDuyet");
        BtnHide("btnDanhGia");
        BtnHide("btnKhoa");
        BtnHide("btnMoKhoa");
    }
}
function confirmDeleteVN() {
    return confirm("Bạn có chắc muốn xóa dữ liệu?");
}
function confirmKhongDuyetVN() {
    return confirm("Bạn có chắc không duyệt dữ liệu?");
}
function BtnActive(id) {
    var ele = document.getElementById(id);
    if (ele != null) {
        if (id =="btnCon")
            ele.className = "btn";
        else ele.className = "btn";
    }
}
function BtnHide(id) {
    var ele = document.getElementById(id);
    if (ele != null) ele.className = "btnhide";
}
function setSelectFull(o) {
    if (o.className == "selected")
        o.classList.remove("selected");
    else
        o.classList.add("selected");
}
function setSelect(o) {
    BtnActive("btnSua");
    BtnActive("btnCon");
    //document.getElementById("btnXoa1").className = "btn";
    if (o.className == "selected") return;
    var list = o.parentElement.getElementsByTagName("tr");
    for (var i = 1; i < list.length; i++) {
        list[i].classList.remove("selected");
    }
    o.classList.add("selected");
    document.getElementById("hidIDSelected").value = o.id;
}
function setCheckAll(o) {
    if (o.checked) {
        BtnActive("btnXoa");
        BtnActive("btnLuu");
        BtnActive("btnDuyet");
        BtnActive("btnDuyet2");
        BtnActive("btnDuyet3");
        BtnActive("btnHuyDuyet");
        BtnActive("btnHuyDuyet2");
        BtnActive("btnHuyDuyet3");
        BtnActive("btnTraVe");
        BtnActive("btnKhongDuyet");
        BtnActive("btnDanhGia");
        BtnActive("btnKhoa");
        BtnActive("btnMoKhoa");
    }
    else {
        BtnHide("btnXoa");
        BtnHide("btnLuu");
        BtnHide("btnDuyet");
        BtnHide("btnDuyet2");
        BtnHide("btnDuyet3");
        BtnHide("btnHuyDuyet");
        BtnHide("btnHuyDuyet2");
        BtnHide("btnHuyDuyet3");
        BtnHide("btnTraVe");
        BtnHide("btnKhongDuyet");
        BtnHide("btnDanhGia");
        BtnHide("btnKhoa");
        BtnHide("btnMoKhoa");
    }
    
    var arr = $("#gridbody").find('td.colchk input[type=checkbox]').prop('checked', o.checked);
}
function setCheckeBox(o) {
    $(o).parent().find('td.colchk input[type=checkbox]').prop('checked', true)
}
function BindProgressBar() {
    $('.progress').mousemove(function (event) {
        var x = (event.clientX - 50) + 'px';
        var y = (event.clientY + 30) + 'px';
        var TienDo = event.pageX - $(this).offset().left;
        var Length = $(this).width();
        var per = parseInt(TienDo / Length * 100);
        if (per < 5) per = 0;
        if (per >= 95) per = 100;
        $('#protooltip').css({ "top": y, "left": x });
        $('#protooltipText').html(per + '%');
    }).mouseover(function () {
        $('#protooltip').css({ "display": "" });
    }).mouseout(function () {
        $('#protooltip').css({ "display": "none" });
    }).mousedown(function (event) {
        if ($(this).attr('disable') == 'disable') {
            MessageThongBao("Đã khóa !");
            return;
        }
        var y = (event.clientY + 30) + 'px';
        var TienDo = event.pageX - $(this).offset().left;
        var Length = $(this).width();
        var per = parseInt(TienDo / Length * 100);
        if (per < 5) per = 0;
        if (per >= 95) per = 100;
        var bar = $(this).find('.progress-bar');
        bar.css({ "width": per + '%' });
        bar.html('  ' + per + '% ');
        var id = $(this).attr('id').replace("pg", "");
        SaveProgressBar(id, null, null, null, per, 1);
    });
}
//Table cell edit==========BEGIN
function BindTextEdit() {
    $("#gridbody .textEdit").dblclick(function (e) {
        e.stopPropagation();
        var currentEle = $(this);
        var value = $(this).html();
        updateVal(currentEle, value);
    });
    $("#gridbody").click(function (e) {
        $(".datepicker").hide();
        $("#KeyListener").focus(); 
    });
}

function updateVal(currentEle, value) {
    var itype = $(currentEle).attr("itype");
    var imax = $(currentEle).attr("imax");
    if (itype=='decimal')
        $(currentEle).html('<input class="thVal tr" type="text" ' + itype + ' maxlength="' + imax + '" value="' + value + '" onfocusout="this.value = formatDecimal(this.value);"/>');
    else $(currentEle).html('<input class="thVal" type="text" ' + itype + ' maxlength="' + imax + '" value="' + value + '"/>');
    BtnActive("btnLuu");
    BtnActive("btnDuyet");
    BtnActive("btnDuyet2");
    BtnActive("btnDuyet3");
    BtnActive("btnHuyDuyet");
    BtnActive("btnHuyDuyet2");
    BtnActive("btnHuyDuyet3");
    BtnActive("btnTraVe");
    BtnActive("btnKhongDuyet");
    BtnActive("btnDanhGia");
    BtnActive("btnKhoa");
    BtnActive("btnMoKhoa");

    if (itype == 'date') {
        $(".thVal").datepicker({
            format: "dd/mm/yyyy",
            todayBtn: "linked",
            language: "vi",
            orientation: "bottom auto",
            autoclose: true,
            daysOfWeekHighlighted: "0,6",
            todayHighlight: true
        }).on("change", function () {
            //checkNull(this.id);
        });
    }
    $(".thVal").focus();
    $(".thVal").keydown(function (e) {
        setCheckeBox(currentEle);
        if (e.keyCode == 13 || e.keyCode == 27) {
            $(currentEle).html($(".thVal").val().trim());
        }
        else if (e.ctrlKey && (e.key === 'A' || e.key === 'a')) {
            $(this).select();
            e.stopPropagation();
        }
    }).click(function (e) {
        e.stopPropagation();
    }).dblclick(function (e) {
        $(this).select();
        e.stopPropagation();
    });
    
    //Handle tab key
    $("#gridbody input").on('keyup', function (e) {
        if (e.which == 9) {
            var obj = $(".thVal");
            if (obj != null) {
                var tmp = obj.val();
                if (tmp != null) tmp = tmp.trim();
                obj.parent().html(tmp);
            }
        }
    });
}
function updateValText() {
    var obj = $(".thVal");
    if (obj != null) {
        var tmp = obj.val();
        if (tmp != null) tmp = tmp.trim();
        setCheckeBox(obj.parent());
        obj.parent().html(tmp);
    }
}
$(document).click(function () { // you can use $('html')
    updateValText();
});
//Table cell edit==========END
//Table cell copy==========BEGIN
var isMouseDown = false;
var startRowIndex = null;
var startCellIndex = null;

function selectTo(cell, tableID) {
    var row = cell.parent();
    var cellIndex = cell.index();
    var rowIndex = row.index();
    var rowStart, rowEnd, cellStart, cellEnd;
    if (rowIndex < startRowIndex) {
        rowStart = rowIndex;
        rowEnd = startRowIndex;
    } else {
        rowStart = startRowIndex;
        rowEnd = rowIndex;
    }
    if (cellIndex < startCellIndex) {
        cellStart = cellIndex;
        cellEnd = startCellIndex;
    } else {
        cellStart = startCellIndex;
        cellEnd = cellIndex;
    }
    for (var i = rowStart; i <= rowEnd; i++) {
        var rowCells = $("#" + tableID).find("tr").eq(i).find("td");
        for (var j = cellStart; j <= cellEnd; j++) {
            rowCells.eq(j).addClass("cellSelected");
        }
    }
}

function BindCellSelect(tableID) {
    $("#" + tableID).find("td").mousedown(function (e) {
        isMouseDown = true;
        var cell = $(this);

        $("#" + tableID).find(".cellSelected").removeClass("cellSelected"); // deselect everything
        if (e.shiftKey) {
            selectTo(cell, tableID);
        } else {
            cell.addClass("cellSelected");
            startCellIndex = cell.index();
            startRowIndex = cell.parent().index();
        }
        return false; // prevent text selection
    })
    .mouseover(function () {
        if (!isMouseDown) return;
        $("#" + tableID).find(".cellSelected").removeClass("cellSelected");
        selectTo($(this), tableID);
    })
    .bind("selectstart", function () {
        return false;
    });
}

function getcellSelectedCells(tableID) {
    $("#" + tableID + " td").each(function () {
        if ($(this).hasClass('cellSelected')) {
            var col = $(this).parent().children().index($(this));
            var row = $(this).parent().parent().children().index($(this).parent());
        }
    })
}
function BindTableExcelEvent() {
    $("#KeyListener").on("keydown", function (e) {
        try {
            var keyCode = (e.keyCode ? e.keyCode : e.which);
            if (e.ctrlKey && (e.key === 'C' || e.key === 'c')) {
                e.preventDefault();
                var eles = document.getElementsByClassName("cellSelected");
                if (eles.length > 0) {
                    var cell = eles[0];
                    var text = $(cell).text();
                    $(this).val(text);
                    $(this).select();
                    document.execCommand('copy');
                }
            }
            else if (e.ctrlKey && (e.key === 'V' || e.key === 'v')) {
                e.preventDefault();
                var text = $(this).val();
                var eles = document.getElementsByClassName("cellSelected");
                for (var i = 0; i < eles.length; i++) {
                    if ($(eles[i]).hasClass("textEdit")) {
                        eles[i].innerHTML = text;
                        setCheckeBox($(eles[i]));
                    }
                }
                BtnActive("btnLuu");
                BtnActive("btnDuyet");
                BtnActive("btnDuyet2");
                BtnActive("btnDuyet3");
                BtnActive("btnHuyDuyet");
                BtnActive("btnHuyDuyet2");
                BtnActive("btnHuyDuyet3");
                BtnActive("btnTraVe");
                BtnActive("btnKhongDuyet");
                BtnActive("btnDanhGia");
                BtnActive("btnKhoa");
                BtnActive("btnMoKhoa");
            }
            else {
                if (keyCode === 8 || keyCode === 46) {
                    e.preventDefault();
                    var eles = document.getElementsByClassName("cellSelected");
                    for (var i = 0; i < eles.length; i++) {
                        if ($(eles[i]).hasClass("textEdit")) {
                            eles[i].innerHTML = "";
                            setCheckeBox($(eles[i]));
                        }
                    }
                    BtnActive("btnLuu");
                    BtnActive("btnDuyet");
                    BtnActive("btnDuyet2");
                    BtnActive("btnDuyet3");
                    BtnActive("btnHuyDuyet");
                    BtnActive("btnHuyDuyet2");
                    BtnActive("btnHuyDuyet3");
                    BtnActive("btnTraVe");
                    BtnActive("btnKhongDuyet");
                    BtnActive("btnDanhGia");
                    BtnActive("btnKhoa");
                    BtnActive("btnMoKhoa");
                }
                if (!e.ctrlKey && !e.tabKey) {
                    if (keyCode != null) {
                        var eles = $('.cellSelected');
                        if (eles.length > 0) {
                            var cell = eles[0];
                            if ((keyCode >= 48 && keyCode <= 57) || (keyCode >= 65 && keyCode <= 90) || (keyCode >= 96 && keyCode <= 105)) {
                                cell.innerHTML = "";
                            }
                            $(cell).dblclick();
                        }
                    }
                }
            }
        }
        catch (err) {

        }

    });
    $(document).mouseup(function () {
        isMouseDown = false;
        //console.log("stop");
        getcellSelectedCells("gridbody");
    });
}
//Table cell copy==========END
function setExpandCol(e, expand) {
    $("#hidExpand").val(expand);

    var i, tabFilter;
    tabFilter = document.getElementById("btnExpand").getElementsByTagName("span");
    for (i = 0; i < tabFilter.length; i++) {
        //tabFilter[i].className = "";
        $(tabFilter[i]).removeClass("active");
    }
    $(e.currentTarget).addClass("active");

    //var grid = $("#gridbody");
    //var min = parseInt(grid.attr("min-width"));
    //var max = parseInt(grid.attr("max-width"));
    if (expand == 1) {
        $(".colAuto").removeClass("colHide0");
        //grid.attr("width", max);
    }
    else {
        $(".colAuto").addClass("colHide0");
        //grid.attr("width", min);
    }
}
function toDayMonthYear(d) {
    if (d == null) return "";
    var todayTime = d;
    var month = format(todayTime.getMonth() + 1);
    var day = format(todayTime.getDate());
    var year = format(todayTime.getFullYear());
    return day + "/" + month + "/" + year;
}
function toMonthDayYear(d) {
    if (d == null) return "";
    var todayTime = d;
    var month = format(todayTime.getMonth() + 1);
    var day = format(todayTime.getDate());
    var year = format(todayTime.getFullYear());
    return month + "/" + day + "/" + year;
}
function formatDecimal(x) {
    if (x == null || x == '') { return ''; }
    var i = 0;
    try { i = parseFloat(x); } catch (err) { i = 0; }
    //return parseFloat(val).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    return parseFloat(i).toFixed(2).toLocaleString('en-us');
}
function formatInteger(x) {
    if (x == null || x == '') { return ''; }
    var i = 0;
    try { i = parseInt(x); } catch (err) { i = 0; }
    return parseInt(i).toLocaleString('en-us');
}
function toDateVN(dateStr) {
    var arr = dateStr.split("/")
    return new Date(arr[2], arr[1] - 1, arr[0])
}
function getMonthVN(dateStr) {
    if (dateStr == null || dateStr == '') { return ''; }
    var arr = dateStr.split("/")
    return "Tháng " + parseInt(arr[1]);
}
function vnDateToString(dateStr) {
    if (dateStr == null || dateStr == '') { return ''; }
    var arr = dateStr.split("/")
    return arr[2] + "/" + arr[1] + "/" + arr[0];
}
function vnDateToString2(dateStr) {
    if (dateStr == null || dateStr == '') { return ''; }
    var arr = dateStr.split("/")
    return arr[2] + "-" + arr[1] + "-" + arr[0];
}
function dateToString(dateStr, iFormat) {
    if (dateStr == null || dateStr == '') { return ''; }
    var arr = dateStr.split("-")
    if (iFormat == 1)//dd/mm/yyyy
        return arr[2] + "/" + arr[1] + "/" + arr[0];
    else if (iFormat == 2)//mm/dd/yyyy
        return arr[1] + "/" + arr[2] + "/" + arr[0];
    else
        return dateStr;
}
function isNull(val) {
    if (val == null || val == '') {
        return true;
    }
    else {
        return false;
    }
}
function removeComa(str,char) {
    if (str == null || str == '') { return ''; }
    var arr = str.split(char)
    var tmp = "";
    for (var i = 0; i < arr.length; i++) {
        tmp = tmp + arr[i];
    }
    return tmp;
}

function toDecimal00(str, char) {
    //,: remove commas, .:removeCommas dot
    str = removeComa(str, char);
    try {
        return parseFloat(str).toFixed(2);
    }
    catch (err) {
        return null;
    }
}
function checkNull(id) {
    var ele = $('#' + id);
    if (ele.val() == null || ele.val() == '') {
        if (id.startsWith('ddl'))
            ele.parent().addClass("errValidate");
        else
            ele.addClass("errValidate");
    }
    else {
        if (id.startsWith('ddl'))
            ele.parent().removeClass("errValidate");
        else
            ele.removeClass("errValidate");}
}
function setError(id) {
    var ele = $('#' + id); if (ele == null) return;
    if (id.startsWith('ddl'))
        ele.parent().addClass("errValidate");
    else
        ele.addClass("errValidate");
}
function clearError(id) {
    var ele = $('#' + id); if (ele == null) return;
    if (id.startsWith('ddl'))
        ele.parent().removeClass("errValidate");
    else
        ele.removeClass("errValidate");
}
function validateNull(id) {
    var ele = $('#' + id);
    if (ele.val() == null || ele.val() == '' || ele.val() == 'null') {
        if (id.startsWith('ddl'))
            ele.parent().addClass("errValidate");
        else
            ele.addClass("errValidate");
        return 1;
    }
    return 0;
}
function formatNhanSu(obj) {
    if (!obj.url) {
        return obj.text;
    }
    var baseUrl = "/AnhNhanSu";
    var $obj = $(
        '<span class="formatAnh"><img src="' + baseUrl + '/' + obj.url + '" class="user" /> ' + obj.text + ' - ' + obj.tenCD + '<i>' + obj.tenCC + '</i><span class="clr"></span></span>'
    );
    return $obj;
};
function formatCCVaNS(obj) {
    var $obj = $(
        '<span class="formatdes">' + obj.text + ' (<i>' + obj.textNS + '</i>' + ' - <i>' + obj.textCD + '</i>)<span class="clr"></span></span>'
    );
    return $obj;
};
function formatDes(obj) {
    var $obj = $(
        '<span class="formatdes">' + obj.text + ' <i>' + obj.des + '</i><span class="clr"></span></span>'
    );
    return $obj;
};
function format2Des(obj) {
    var $obj = $(
        '<span class="format2des">' + obj.text + ' <i>' + obj.des + '</i><span class="clr"></span></span>'
    );
    return $obj;
};
function getFileSize(iSize) {
    var iGB = 1024 * 1024 * 1024;
    var iMB = 1024 * 1024;
    var iKB = 1024;
    var sizeName = '';
    if (iSize > iGB)
        sizeName = (iSize / iGB).toFixed(2) + " GB";
    else if (iSize > iMB)
        sizeName = (iSize / iMB).toFixed(2) + " MB";
    else if (iSize > iKB)
        sizeName = (iSize / iKB).toFixed(0) + " KB";
    else sizeName = iSize + " B";
    return sizeName;
}
function getFileSizeFix(iSize) {
    var iGB = 1024 * 1024 * 1024;
    var iMB = 1024 * 1024;
    var iKB = 1024;
    var sizeName = '';
    if (iSize > iGB)
        sizeName = (iSize / iGB).toFixed(0) + " GB";
    else if (iSize > iMB)
        sizeName = (iSize / iMB).toFixed(0) + " MB";
    else if (iSize > iKB)
        sizeName = (iSize / iKB).toFixed(0) + " KB";
    else sizeName = iSize + " B";
    return sizeName;
}
function NullToZero(val) {
    if (val == null || val == 'null') {
        return "0";
    }
    return val;
}
function EmptyNull(val) {
    if (val == null || val == 'null') {
        return "";
    }
    return val;
}
function BindDecimalFlex(val) {
    if (val == null || val == 'null') {
        return "";
    }
    try { return parseFloat(val).toFixed(2).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ","); } catch (err) { return "N/A"; }
    //return (Math.round(val * 100) / 100).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}
function BindDecimal1(val) {
    if (val == null || val == 'null') {
        return "";
    }
    try { return parseFloat(val).toFixed(1).replace(/\B(?=(\d{3})+(?!\d))/g, ","); } catch (err) { return "N/A"; }
    //try { return parseFloat(val).toFixed(1).toLocaleString('en-us'); } catch (err) { return "N/A"; }
}
function BindDecimal2(val) {
    if (val == null || val == 'null') {
        return "";
    }
    try { return parseFloat(val).toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ","); } catch (err) { return "N/A"; }
}
function NumberJoinChar(val, char) {

}
function BindInteger(val) {
    if (val == null || val == 'null') {
        return "";
    }
    return val.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}
function EmptyPhanTram(val) {
    if (val == null || val == 'null') {
        return "";
    }
    if (val.length == 0) return "";
    return val + '%';
}
function getFloat(val) {
    if (val == null || val == 'null') {
        return 0;
    }
    return parseFloat(val);
}
function getTienDo(val) {
    if (val == null || val == 'null') {
        return '<svg viewBox="0 0 36 36" class="circular-chart "><path class="circle-bg" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"></path><path class="circle" stroke-dasharray=", 100" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"></path><text x="18" y="21.35" class="percentage"></text></svg>';
    }
    var TyLe = parseInt(val);
    if (TyLe >= 100)
        return '<svg viewBox="0 0 36 36" class="circular-chart blue"><path class="circle-bg" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"></path><path class="circle" stroke-dasharray="' + TyLe + ', 100" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"></path><text x="18" y="21.35" class="percentage">' + TyLe + '%</text></svg>';
    else if (TyLe >= 90)
        return '<svg viewBox="0 0 36 36" class="circular-chart green"><path class="circle-bg" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"></path><path class="circle" stroke-dasharray="' + TyLe + ', 100" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"></path><text x="18" y="21.35" class="percentage">' + TyLe + '%</text></svg>';
    else if (TyLe >= 70)
        return '<svg viewBox="0 0 36 36" class="circular-chart banana"><path class="circle-bg" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"></path><path class="circle" stroke-dasharray="' + TyLe + ', 100" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"></path><text x="18" y="21.35" class="percentage">' + TyLe + '%</text></svg>';
    else if (TyLe >= 50)
        return '<svg viewBox="0 0 36 36" class="circular-chart yellow"><path class="circle-bg" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"></path><path class="circle" stroke-dasharray="' + TyLe + ', 100" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"></path><text x="18" y="21.35" class="percentage">' + TyLe + '%</text></svg>';
    else if (TyLe >= 30)
        return '<svg viewBox="0 0 36 36" class="circular-chart orange"><path class="circle-bg" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"></path><path class="circle" stroke-dasharray="' + TyLe + ', 100" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"></path><text x="18" y="21.35" class="percentage">' + TyLe + '%</text></svg>';
    else if (TyLe >= 1)
        return '<svg viewBox="0 0 36 36" class="circular-chart red"><path class="circle-bg" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"></path><path class="circle" stroke-dasharray="' + TyLe + ', 100" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"></path><text x="18" y="21.35" class="percentage">' + TyLe + '%</text></svg>';
    else return '<svg viewBox="0 0 36 36" class="circular-chart"><path class="circle-bg" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"></path><path class="circle" stroke-dasharray="' + TyLe + ', 100" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"></path><text x="18" y="21.35" class="percentage">' + TyLe + '%</text></svg>';
}
function MessageLoi(msg)
{
    Notify(msg, null, null, 'danger');
}
function MessageCanhBao(msg) {
    Notify(msg, null, null, 'warning');
}
function MessageThongBao(msg) {
    Notify(msg, null, null, 'info');
}
function MessageThanhCong(msg) {
    Notify(msg, null, null, 'success');
}
// Restricts input for the set of matched elements to the given inputFilter function.
(function ($) {
    $.fn.inputFilter = function (inputFilter) {
        return this.on("input keydown keyup mousedown mouseup select contextmenu drop", function () {
            if (inputFilter(this.value)) {
                this.oldValue = this.value;
                this.oldSelectionStart = this.selectionStart;
                this.oldSelectionEnd = this.selectionEnd;
            } else if (this.hasOwnProperty("oldValue")) {
                this.value = this.oldValue;
                this.setSelectionRange(this.oldSelectionStart, this.oldSelectionEnd);
            } else {
                this.value = "";
            }
        });
    };
    $.fn.offFilter = function () {
        return this.off("input keydown keyup mousedown mouseup select contextmenu drop");
    };
}(jQuery));