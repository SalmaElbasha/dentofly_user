import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/controllers/chat_controller.dart';

class ConversationListTabview extends StatefulWidget {
  final TabController? tabController;
  const ConversationListTabview({super.key, this.tabController});

  @override
  _ConversationListTabviewState createState() => _ConversationListTabviewState();
}

class _ConversationListTabviewState extends State<ConversationListTabview> {
  bool _tabsEnabled = false;

  // Call this method from your logic to enable/disable taps
  void setTabsEnabled(bool enabled) {
    if (mounted) {
      setState(() {
        _tabsEnabled = enabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatController>(
      builder: (context, chatProvider, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Row(
            children: [
              AbsorbPointer(
                absorbing: !_tabsEnabled,
                child: TabBar(
                  controller: widget.tabController,
                  unselectedLabelColor: Colors.grey,
                  isScrollable: true,
                  dividerColor: Colors.transparent,
                  indicatorColor: Theme.of(context).primaryColor,
                  labelColor: Theme.of(context).primaryColor,
                  labelStyle: textMedium,
                  indicatorWeight: 1,
                  tabAlignment: TabAlignment.start,
                  labelPadding: EdgeInsets.only(
                    right: chatProvider.isActiveSuffixIcon && chatProvider.messageList.isNotEmpty
                        ? 10
                        : 25,
                  ),
                  indicatorPadding: const EdgeInsets.only(right: 10),
                  tabs: [
                    SizedBox(
                      height: 35,
                      child: Center(
                        child: Text(getTranslated('delivery-man', context)!),
                      ),
                    ),
                    // TODO: add more tabs here
                  ],
                  onTap: _tabsEnabled
                      ? (index) {
                    setTabsEnabled(false);
                    if (chatProvider.isActiveSuffixIcon) {
                      chatProvider.setUserTypeIndex(
                          context, widget.tabController!.index,
                          searchActive: true);
                    } else {
                      chatProvider.setUserTypeIndex(
                          context, widget.tabController!.index);
                    }
                  }
                      : null,
                ),
          ),

              // Spacer to push tabs to the left
              const Expanded(child: SizedBox()),
            ],
          ),
        );
      },
    );
  }
}
