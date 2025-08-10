import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/controllers/address_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/screens/login_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/screens/dashboard_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/maintenance/maintenance_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/screens/order_details_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/screens/product_details_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/restock/controllers/restock_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/restock/widgets/restock_ bottom_sheet.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/models/config_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/screens/wallet_screen.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/push_notification/models/notification_body.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/screens/inbox_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/notification/screens/notification_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class NotificationHelper {
  static Future<void> initialize(FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
    var androidInitialize = const AndroidInitializationSettings('notification_icon');
    var iOSInitialize = const DarwinInitializationSettings();
    var initializationsSettings = InitializationSettings(android: androidInitialize, iOS: iOSInitialize);

    flutterLocalNotificationsPlugin.initialize(initializationsSettings, onDidReceiveNotificationResponse: (NotificationResponse load) async {
      try {
        NotificationBody payload;

        if (load.payload!.isNotEmpty) {
          payload = NotificationBody.fromJson(jsonDecode(load.payload!));

          if (payload.type == 'order') {
            Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (context) => OrderDetailsScreen(orderId: payload.orderId, isNotification: true)));
          } else if (payload.type == 'wallet') {
            Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (context) => const WalletScreen()));
          } else if (payload.type == 'chatting') {
            Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (context) => InboxScreen(isBackButtonExist: true, initIndex: payload.messageKey == 'message_from_delivery_man' ? 0 : 1, fromNotification: true)));
          } else if (payload.type == 'product_restock_update') {
            Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (context) => ProductDetails(productId: int.parse(payload.productId!), slug: payload.slug, isNotification: true)));
          } else {
            Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (context) => const NotificationScreen(fromNotification: true)));
          }
        }
      } catch (_) {}
      return;
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (!kIsWeb && message.data.isNotEmpty) {
        NotificationBody notificationBody = convertNotification(message.data);

        // 🚫 Don't show native notification if it's a restock update
        if (notificationBody.type != 'product_restock_update') {
          await showNotification(message, flutterLocalNotificationsPlugin, true);
        }

        if (message.data['type'] == 'block') {
          Provider.of<AuthController>(Get.context!, listen: false).clearSharedData();
          Provider.of<AddressController>(Get.context!, listen: false).getAddressList();
          Navigator.of(Get.context!).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
        }

        if (message.data['type'] == 'maintenance_mode') {
          final SplashController splashProvider = Provider.of<SplashController>(Get.context!, listen: false);
          await splashProvider.initConfig(Get.context!, null, null);

          ConfigModel? config = splashProvider.configModel;
          bool isMaintenanceRoute = splashProvider.isMaintenanceModeScreen();

          if (config?.maintenanceModeData?.maintenanceStatus == 1 &&
              (config?.maintenanceModeData?.selectedMaintenanceSystem?.customerApp == 1)) {
            Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (_) => const MaintenanceScreen()));
          } else if (config?.maintenanceModeData?.maintenanceStatus == 0 && isMaintenanceRoute) {
            Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (_) => const DashBoardScreen()));
          }
        }

        if (message.data['type'] == 'product_restock_update' &&
            !Provider.of<RestockController>(Get.context!, listen: false).isBottomSheetOpen) {
          Provider.of<RestockController>(Get.context!, listen: false).setBottomSheetOpen(true);
          await showModalBottomSheet(
            context: Get.context!,
            isScrollControlled: true,
            backgroundColor: Theme.of(Get.context!).primaryColor.withOpacity(0),
            builder: (con) => RestockSheetWidget(notificationBody: notificationBody),
          );
          Provider.of<RestockController>(Get.context!, listen: false).setBottomSheetOpen(false);
        }
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      if (!kIsWeb && message.data.isNotEmpty) {
        NotificationBody notificationBody = convertNotification(message.data);

        if (notificationBody.type == 'order') {
          Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (context) => OrderDetailsScreen(orderId: notificationBody.orderId, isNotification: true)));
        } else if (notificationBody.type == 'wallet') {
          Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (context) => const WalletScreen()));
        } else if (notificationBody.type == 'chatting') {
          Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (context) => InboxScreen(isBackButtonExist: true, fromNotification: true, initIndex: notificationBody.messageKey == 'message_from_delivery_man' ? 0 : 1)));
        } else if (notificationBody.type == 'product_restock_update') {
          Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (context) => ProductDetails(productId: int.parse(notificationBody.productId!), slug: notificationBody.slug, isNotification: true)));
        } else {
          Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (context) => const NotificationScreen(fromNotification: true)));
        }
      }
    });
  }

  static Future<void> showNotification(RemoteMessage message, FlutterLocalNotificationsPlugin fln, bool data) async {
    if (!Platform.isIOS) {
      String? title = message.data['title'] ?? message.notification?.title;
      String? body = message.data['body'] ?? message.notification?.body;
      NotificationBody notificationBody = convertNotification(message.data);

      if (notificationBody.type != 'product_restock_update') {
        await showBigTextNotification(title, body ?? '', null, notificationBody, fln);
      }
    }
  }

  static Future<void> showBigTextNotification(String? title, String body, String? orderID, NotificationBody? notificationBody, FlutterLocalNotificationsPlugin fln) async {
    BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      body,
      htmlFormatBigText: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
    );
    AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'Dentofly', 'Dentofly',
      importance: Importance.max,
      styleInformation: bigTextStyleInformation,
      priority: Priority.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification'),
    );
    NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await fln.show(0, title, body, platformChannelSpecifics,
        payload: notificationBody != null ? jsonEncode(notificationBody.toJson()) : null);
  }

  static NotificationBody convertNotification(Map<String, dynamic> data) {
    if (data['type'] == 'order') {
      return NotificationBody(type: 'order', orderId: int.parse(data['order_id']));
    } else if (data['type'] == 'wallet') {
      return NotificationBody(type: 'wallet');
    } else if (data['type'] == 'chatting') {
      return NotificationBody(type: 'chatting', messageKey: data['message_key']);
    } else if (data['type'] == 'product_restock_update') {
      return NotificationBody(
        type: 'product_restock_update',
        title: data['title'],
        image: data['image'],
        productId: data['product_id'].toString(),
        slug: data['slug'],
        status: data['status'],
      );
    } else {
      return NotificationBody(type: 'notification');
    }
  }
}

@pragma('vm:entry-point')
Future<dynamic> myBackgroundMessageHandler(RemoteMessage message) async {
  // Handle background messages if needed
}


