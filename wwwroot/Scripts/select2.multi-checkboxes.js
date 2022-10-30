jQuery(function ($) {
    $.fn.select2.amd.require([
        'select2/selection/single',
        'select2/selection/placeholder',
        'select2/selection/allowClear',
        'select2/dropdown',
        'select2/dropdown/search',
        'select2/dropdown/attachBody',
        'select2/utils'
    ], function (SingleSelection, Placeholder, AllowClear, Dropdown, DropdownSearch, AttachBody, Utils) {

        var SelectionAdapter = Utils.Decorate(
            SingleSelection,
            Placeholder
        );

        SelectionAdapter = Utils.Decorate(
            SelectionAdapter,
            AllowClear
        );

        var DropdownAdapter = Utils.Decorate(
            Utils.Decorate(
                Dropdown,
                DropdownSearch
            ),
            AttachBody
        );
        var base_element = $('.select2-multiple2')
        $('.select2-multiple2').select2({
            placeholder: 'Select multiple items',
            selectionAdapter: SelectionAdapter,
            dropdownAdapter: DropdownAdapter,
            dropdownAutoWidth: true,
            allowClear: true,
            templateResult: function (data) {

                if (!data.id) { return data.text; }

                var $res = $('<div></div>');

                $res.text(data.text);
                $res.addClass('wrap');

                return $res;
            },
            templateSelection: function (data) {
                if (!data.id) { return data.text; }
                var selected = ($(base_element).val() || []).length;
                var total = $('option', $(base_element)).length;
                return "Selected " + selected + " of " + total;
            }
        })
    });

});