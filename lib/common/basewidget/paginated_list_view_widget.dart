import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';

class PaginatedListView extends StatefulWidget {
  final ScrollController? scrollController;
  final Function(int? offset) onPaginate;
  final int? totalSize;
  final int? offset;
  final int? limit;
  final Widget itemView;
  final bool enabledPagination;
  final bool reverse;

  const PaginatedListView({
    super.key,
    this.scrollController,
    required this.onPaginate,
    required this.totalSize,
    required this.offset,
    required this.itemView,
    this.enabledPagination = true,
    this.reverse = false,
    this.limit = 10,
  });

  @override
  State<PaginatedListView> createState() => _PaginatedListViewState();
}

class _PaginatedListViewState extends State<PaginatedListView> {
  late ScrollController _localScrollController;
  bool _isInternalController = false;

  int? _offset;
  late List<int?> _offsetList;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // استخدام controller من widget أو إنشاء واحد داخلي
    if (widget.scrollController == null) {
      _localScrollController = ScrollController();
      _isInternalController = true;
    } else {
      _localScrollController = widget.scrollController!;
    }

    _offset = 1;
    _offsetList = [1];

    _localScrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_localScrollController.position.pixels ==
        _localScrollController.position.maxScrollExtent &&
        widget.totalSize != null &&
        !_isLoading &&
        widget.enabledPagination) {
      if (mounted) {
        _paginate();
      }
    }
  }

  void _paginate() async {
    int pageSize = (widget.totalSize! / widget.limit!).ceil();
    if (_offset! < pageSize && !_offsetList.contains(_offset! + 1)) {
      setState(() {
        _offset = _offset! + 1;
        _offsetList.add(_offset);
        _isLoading = true;
      });

      await widget.onPaginate(_offset);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      if (_isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    if (_isInternalController) {
      _localScrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.offset != null) {
      _offset = widget.offset;
      _offsetList = [];
      for (int index = 1; index <= widget.offset!; index++) {
        _offsetList.add(index);
      }
    }

    return ListView(
      controller: _localScrollController,
      reverse: widget.reverse,
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      children: [
        if (!widget.reverse) widget.itemView,

        if (widget.totalSize != null &&
            _offset! < (widget.totalSize! / widget.limit!).ceil() &&
            !_offsetList.contains(_offset! + 1))
          Center(
            child: Padding(
              padding: _isLoading
                  ? const EdgeInsets.all(Dimensions.paddingSizeSmall)
                  : EdgeInsets.zero,
              child:
              _isLoading ? const CircularProgressIndicator() : const SizedBox(),
            ),
          ),

        if (widget.reverse) widget.itemView,
      ],
    );
  }
}
