(function () {

	function PopLayer(args) {
		this.title = args.title || "";
		this.content = args.content || "";
		this.url = args.url || "";
		this.height = args.height || "";
		this.width = args.width || "";
		this.isFullScreen = (typeof args.isFullScreen === "boolean") ? args.isFullScreen : false;
		this.isModal = (typeof args.isModal === "boolean") ? args.isModal : true;
		this.moveable = (typeof args.moveable === "boolean") ? args.moveable : true;
		this.document = args.document || document;
		this.isDown = false;
		this.offset = {
			"width": 0,
			"height": 0
		};
		this.id = ++top.PopLayer.id;
		var modal = this.getElement();

		if (this.isModal) {
			this.myModal = modal.myModal;
		}
		this.myPop = modal.myPop;
		if (this.width != "") { this.myPop.css("max-width", this.width + "px"); }
		top.PopLayer.instances[this.id] = this;
		this.init();
		var iframe = $("#iframe")[0];
		iframe.contentWindow.focus();
	};

	PopLayer.prototype = {

		init: function () {
			this.initContent();
			this.initEvent();
		},

		initContent: function () {
			if (this.isModal) {
				$("body", this.document).append(this.myModal);
				this.myModal.show();
			}
			$("body", this.document).append(this.myPop);
			$(".myPop-title-value", this.myPop).html(this.title);
			if (this.isFullScreen) {
				this.myPop.css("top", "0");
				this.myPop.css("bottom", "0");
				this.myPop.css("left", "0");
				this.myPop.css("right", "0");
				this.myPop.css("width", "100%");
				this.myPop.css("height", "100%");
			}
			else {
				this.myPop.css("top", (this.document.documentElement.clientHeight - this.myPop.height()) / 2 + "px");
				this.myPop.css("left", (this.document.documentElement.clientWidth - this.myPop.width()) / 2 + "px");
			}
			this.myPop.show();
		},

		initEvent: function () {
			var $this = this;
			$(".myPop-title", this.myPop).on("mousedown", function (e) {
				$this.isDown = true;
				var event = window.event || e;
				$this.offset.height = event.clientY - $this.myPop.offset().top;
				$this.offset.width = event.clientX - $this.myPop.offset().left;
				return false;
			});
			$(this.document).mousemove(function (e) {
				if ($this.isDown && $this.moveable) {
					var event = window.event || e;
					var top = event.clientY - $this.offset.height,
						left = event.clientX - $this.offset.width,
						maxL = $this.document.documentElement.clientWidth - $this.myPop.width(),
						maxT = $this.document.documentElement.clientHeight - $this.myPop.height();
					left = left < 0 ? 0 : left;
					left = left > maxL ? maxL : left;
					top = top < 0 ? 0 : top;
					top = top > maxT ? maxT : top;
					$this.myPop.css("top", top + "px");
					$this.myPop.css("left", left + "px");
				}
				return false;
			}).mouseup(function (e) {
				if ($this.isDown) {
					$this.isDown = false;
				}
				return false;
			});
			//关闭事件
			$(".myPop-close", this.myPop).on('click', function () {
				$this.destroy();
				return false;
			});
			$(".myModal").on('click', function () {
				//$this.destroy();
				return false;
			});
		},

		getElement: function () {
			if (this.url == "") {
				return {
					"myModal": $("<div class='myModal'></div>", this.document),
					"myPop": $("<div class='myPop'>" +
						"<h2 class='myPop-title'>" +
						"<span class='myPop-title-value'></span>" +
						"<span class='myPop-close' id='myPop-close'>×</span>" +
						"</h2>" +
						"<div class='myPop-content'>" + this.content + "</div>" +
						"</div>", this.document)
				};
			}
			else {
				return {
					"myModal": $("<div class='myModal'></div>", this.document),
					"myPop": $("<div class='myPop'>" +
						"<h2 class='myPop-title'>" +
						"<span class='myPop-title-value'></span>" +
						"<span class='myPop-close' id='myPop-close'>×</span>" +
						"</h2>" +
						"<div class='myPop-content'><iframe id='iframe' src='" + this.url + "' style='width:100%;height:100%;min-height:" + this.height + "px;min-width:" + this.width + "px;'></iframe ></div>" +
						//"<div class='myPop-content'><iframe id='iframe' src='" + this.url + "' style='width:100%;height:" + this.height + "px;'></iframe ></div>" +
						"</div>", this.document)
				};
			}
		},

		destroy: function () {
			//清除显示层
			this.myPop.remove();
			//清除存在的遮罩层
			if (this.isModal) {
				this.myModal.remove();
			}
			//销毁池中对象
			delete top.PopLayer.instances[this.id];
			//计数器退栈
			top.PopLayer.id--;
		}
	};

	if (!top.PopLayer) {
		PopLayer.zIndexCounter = 1000;//z-index计数器
		PopLayer.id = 0;//层对象计数
		PopLayer.instances = {};//层对象池

		top.PopLayer = PopLayer;
	}

})();